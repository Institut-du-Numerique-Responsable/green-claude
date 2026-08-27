#!/usr/bin/env ruby

require "yaml"

root = ENV.fetch("COMMUNITY_ROOT", File.expand_path("..", __dir__))
forms_dir = File.join(root, ".github", "ISSUE_TEMPLATE")
errors = []

load_yaml = lambda do |path|
  YAML.safe_load(File.read(path), permitted_classes: [], aliases: false)
rescue StandardError => e
  errors << "#{File.basename(path)}: YAML invalide (#{e.message})"
  nil
end

%w[bug.yml false-positive.yml new-rule.yml].each do |name|
  path = File.join(forms_dir, name)
  next unless File.file?(path)

  form = load_yaml.call(path)
  next unless form.is_a?(Hash)

  errors << "#{name}: name manquant" unless form["name"].is_a?(String) && !form["name"].empty?
  errors << "#{name}: description manquante" unless form["description"].is_a?(String) && !form["description"].empty?
  body = form["body"]
  unless body.is_a?(Array) && !body.empty?
    errors << "#{name}: body doit être une liste non vide"
    next
  end

  ids = []
  required = false
  body.each_with_index do |field, index|
    unless field.is_a?(Hash)
      errors << "#{name}: body[#{index}] doit être un objet"
      next
    end
    type = field["type"]
    errors << "#{name}: type non supporté #{type.inspect}" unless %w[markdown input textarea dropdown checkboxes].include?(type)
    next if type == "markdown"

    id = field["id"]
    errors << "#{name}: id manquant dans body[#{index}]" unless id.is_a?(String) && id.match?(/\A[a-zA-Z][a-zA-Z0-9_-]*\z/)
    ids << id if id.is_a?(String)
    attributes = field["attributes"]
    errors << "#{name}: attributes.label manquant pour #{id || index}" unless attributes.is_a?(Hash) && attributes["label"].is_a?(String)
    if type == "dropdown"
      options = attributes.is_a?(Hash) ? attributes["options"] : nil
      errors << "#{name}: options manquantes pour #{id || index}" unless options.is_a?(Array) && !options.empty?
    end
    required ||= field.dig("validations", "required") == true
  end
  errors << "#{name}: ids dupliqués" unless ids.uniq.length == ids.length
  errors << "#{name}: aucun champ obligatoire" unless required
end

config_path = File.join(forms_dir, "config.yml")
if File.file?(config_path)
  config = load_yaml.call(config_path)
  if config.is_a?(Hash)
    errors << "config.yml: blank_issues_enabled doit valoir false" unless config["blank_issues_enabled"] == false
    links = config["contact_links"]
    errors << "config.yml: contact_links doit être une liste non vide" unless links.is_a?(Array) && !links.empty?
  end
end

unless errors.empty?
  warn errors.join("\n")
  exit 1
end

puts "OK - schéma des formulaires GitHub valide"
