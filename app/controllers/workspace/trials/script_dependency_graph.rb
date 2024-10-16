require "open3"

module ::Workspace::Trials::ScriptDependencyGraph
  include ApplicationHelper
  extend ActiveSupport::Concern

  included do
    helper_method :scripts_dependency_svg_graph,
      :scripts_dependency_svg_graph_cache_signature
  end

  def scripts_dependency_svg_graph_cache_signature(trial, type = :start)
    CacheSignature.signature type, trial.task.task_specification_id,
      trial.scripts.reorder(key: :asc).select(:state).map(&:state)
  end

  def scripts_dependency_svg_graph(trial, type = :start)
    scripts = trial.scripts.reorder(key: :asc).to_a

    sanitize = lambda do |str|
      str.gsub(/[^0-9A-Za-z.\-]/, "_")
    rescue
      ""
    end

    build_arcs = lambda do |scripts, type|
      scripts.flat_map do |s|
        s[type] && s[type].map { |k, v| v || k }.sort_by { |s| s[:key] }
          .map do |dependency|
          [sanitize.call(dependency["script_key"]),
           sanitize.call(s[:key]),
           (dependency["states"] || ["passed"]).map { |w| sanitize.call(w) }]
        end
      end.compact
    end

    arcs2graphviz = lambda do |arcs, color|
      arcs.map do |a|
        %("#{a[0]}" -> "#{a[1]}"  [id="#{a[0]}_#{a[1]}", ) +
          %( color="#{color}", label=" #{a[2].join('\\n')}"];)
      end
    end

    add_node_classes = lambda do |svg|
      xml = Nokogiri::XML(svg)
      xml.css(".node").each do |node|
        id = node.attr("id")
        state = begin
            scripts.find { |s| sanitize.call(s.key) == id }[:state]
          rescue
            "undefined"
          end
        node["class"] = [node.attr("class"), state].compact.join(" ")
      end
      _svg = xml.to_s
    end

    adjust_size_params = lambda do |svg|
      xml = Nokogiri::XML(svg)
      outer_svg_node = xml.css("svg").first
      outer_svg_node["max-height"] = outer_svg_node["height"]
      outer_svg_node.remove_attribute("height")
      # outer_svg_node['max-width'] = outer_svg_node['width']
      # outer_svg_node.remove_attribute('width')
      _svg = xml.to_s
    end

    graphviz_nodes = scripts.map { |s| s.slice(:key, :name) }
      .map do |n|
      id = sanitize.call(n[:key])
      label = sanitize.call(n[:name])
      %( "#{id}" [id="#{id}", label="#{label}"];)
    end

    case type
    when :start
      start_arcs = build_arcs.call(scripts, :start_when).select(&:present?)
      graphviz_start_arcs = arcs2graphviz.call(start_arcs, "green")
      graphviz_terminate_arcs = []
    when :terminate
      graphviz_start_arcs = []
      terminate_arcs = build_arcs.call(scripts, :terminate_when)
      graphviz_terminate_arcs = arcs2graphviz.call(terminate_arcs, "red")
    end

    graphviz = %(
      digraph "Scripts Dependency Graph" {
        stylesheet="#{ActionController::Base.helpers.stylesheet_path(stylesheet_chooser)}"
        id = "scripts-dependency-graph"
        #{graphviz_nodes.join("\n    ")}
        #{graphviz_start_arcs.join("\n    ")}
        #{graphviz_terminate_arcs.join("\n    ")}
      }
    )

    graphviz_svg, _log = Open3.capture2("dot -T svg", stdin_data: graphviz)

    _svg = adjust_size_params.call(add_node_classes.call(graphviz_svg))
  end
end
