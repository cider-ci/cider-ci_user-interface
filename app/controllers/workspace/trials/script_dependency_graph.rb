require 'open3'

module ::Workspace::Trials::ScriptDependencyGraph
  extend ActiveSupport::Concern

  included do
    helper_method :scripts_dependency_svg_graph,
      :scripts_dependency_svg_graph_cache_signature
  end

  def scripts_dependency_svg_graph_cache_signature(trial, _type = :start)
    CacheSignature.signature trial.task.task_specification_id,
      trial.scripts.with_indifferent_access.map { |k, v| v || k } \
      .sort_by { |s| s[:key] || s[:name] || s[:stated_at] || s[:skipped_at] } \
      .map { |s| s[:state] }
  end

  def scripts_dependency_svg_graph(trial, type = :start)
    scripts = trial.scripts.with_indifferent_access
    sanitize = lambda do|str|
      str.gsub(/[^0-9A-Za-z.\-]/, '_') rescue ''
    end

    build_arcs = lambda do|scripts, type|
        scripts.flat_map do |key, map|
          map[type] && map[type].map { |k, v| v || k }.map do |dependency|
            [sanitize.(dependency['script']),
             sanitize.(key),
             (dependency['states'] || ['passed']).map { |w| sanitize.(w) }]
          end
        end.compact
    end

    arcs2graphviz = lambda do|arcs, color|
      arcs.map do|a|
        %("#{a[0]}" -> "#{a[1]}"  [id="#{a[0]}_#{a[1]}", ) +
        %( color="#{color}", label=" #{a[2].join('\\n')}"];)
      end
    end

    add_node_classes = lambda do|svg|
      xml = Nokogiri::XML(svg)
      xml.css('.node').each do |node|
        id = node.attr('id')
        state = scripts[id]['state'] rescue 'undefined'
        node['class'] = [node.attr('class'), state].compact.join(' ')
      end
      _svg = xml.to_s
    end

    graphviz_nodes = scripts.with_indifferent_access
      .map { |k, v| v.merge(key: (v[:key] || k), name: (v[:name] || k)) }
      .map { |n| n.slice(:key, :name) }.map do |n|
        id = sanitize.(n[:key])
        label = sanitize.(n[:name])
        %( "#{id}" [id="#{id}", label="#{label}"];)
      end

    case type
    when :start
      start_arcs = build_arcs.(scripts, 'start-when')
      graphviz_start_arcs = arcs2graphviz.(start_arcs, 'green')
      graphviz_terminate_arcs = []
    when :terminate
      graphviz_start_arcs = []
      terminate_arcs = build_arcs.(scripts, 'terminate-when')
      graphviz_terminate_arcs = arcs2graphviz.(terminate_arcs, 'red')
    end

    graphviz = %(
      digraph "Scripts Dependency Graph" {
        stylesheet="#{ActionController::Base.helpers.stylesheet_path('application')}"
        id = "scripts-dependency-graph"
        #{graphviz_nodes.join("\n    ")}
        #{graphviz_start_arcs.join("\n    ")}
        #{graphviz_terminate_arcs.join("\n    ")}
      }
    )

    graphviz_svg, _log = Open3.capture2('dot -T svg', stdin_data: graphviz)

    _svg = add_node_classes.(graphviz_svg)
  end

end
