Rails.application.config.action_cable.use_faye = true
Rails.application.config.action_cable.disable_request_forgery_protection = true
Faye::WebSocket.load_adapter 'thin'