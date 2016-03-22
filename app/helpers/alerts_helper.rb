module AlertsHelper
  def bootstrap_alert_type(item)
    case (item['type'] || item['class'])
    when 'error'
      'alert-danger'
    else
      'alert-warning'
    end
  end
end
