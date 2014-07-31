require 'uglifier'

def make_source
  @prefix = common_class_prefix if meta(:namespace) == "true"
  transform = meta(:minify) ? lambda { |source| Uglifier.compile(source)} : nil
  generate_template(meta(:file) || "talk.js", "talk.js.erb", transform)
end

def autogenerated_warning
  <<-AUTOGEN_DONE
// Autogenerated from Talk
// Please do not edit this file directly. Instead, modify the underlying .talk files.
  AUTOGEN_DONE
end

def comment_block(tag, indent_level=0)
  lines = []
  indent = "\t" * indent_level
  lines.push(indent + "/*")
  lines.push(wrap_text_to_width(tag[:description], 80, indent + " *  ")) unless tag[:description].nil?
  lines.push(indent + " *  ")
  lines.push(indent + " *  " + definition_reference(tag))
  lines.push(indent + " */")

  lines.join("\n")
end

def definition_reference(tag)
  "@talkFile #{tag[:__meta][:file]}:#{tag[:__meta][:line]}"
end

def class_line(cls)
  @rendered ||= Set.new
  out = []

  return nil unless cls[:implement]
  return nil if cls[:name] == rootclass
  return nil if @rendered.include? cls
  @rendered.add(cls)
  out << class_line(class_named(cls[:inherits])) unless cls[:inherits].nil?
  out << comment_block(cls)
  out << "// " + cls[:name]

  fields = {}

  puts cls[:name]
  cls[:field].each do |field|
    mapped = mapped_name(cls[:name], field[:name], :field)
    fields[mapped] = {typeStack:field[:type]}
    fields[mapped][:canonicalName] = field[:name] unless mapped == field[:name]
  end

  out << "TalkObject.addClass('#{cls[:name]}', #{fields.to_json}, '#{truncated_name(superclass(cls))}');"
  out.join("\n")
end

def protocol_line(proto)
  methods = proto[:method].map { |m| m[:name] }
  out = []
  out << comment_block(proto)
  out << "TalkObject.addProtocol('#{proto[:name]}', #{methods.to_json});"
  out.join("\n")
end

def glossary_line(glossary)
  terms = {}
  glossary[:term].each { |term| terms[term[:name]] = term[:value] }

  out = []
  out << comment_block(glossary)
  out << "TalkObject.addGlossary('#{glossary[:name]}', #{terms.to_json});"
  out.join("\n")
end

def enumeration_line(enumeration)
  constants = {}
  enumeration[:constant].each { |constant| constants[constant[:name]] = constant[:value] }

  out = []
  out << comment_block(enumeration)
  out << "TalkObject.addEnumeration('#{enumeration[:name]}', #{constants.to_json});"
  out.join("\n")
end
