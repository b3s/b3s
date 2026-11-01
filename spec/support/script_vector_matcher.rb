# frozen_string_literal: true

RSpec::Matchers.define :be_free_of_script_vectors do
  unsafe_elements = %w[animate applet base embed form input link math meta
                       object script set style svg template]
  unsafe_attributes = %w[action formaction srcdoc xlink:href]
  unsafe_schemes = %r{\A(javascript|vbscript|data:(?!image/(avif|gif|jpeg|png|webp)[;,]))}

  find_vectors = lambda do |html|
    fragment = Nokogiri::HTML5::DocumentFragment.parse(html.to_s)
    fragment.xpath(".//*").flat_map do |node|
      found = unsafe_elements.include?(node.name.downcase) ? ["<#{node.name}>"] : []
      found + node.attribute_nodes.filter_map do |attr|
        name = attr.name.downcase
        value = attr.value.gsub(/[\u0000-\u0020]/, "").downcase
        "#{node.name}@#{name}" if name.start_with?("on") ||
                                  unsafe_attributes.include?(name) ||
                                  value.match?(unsafe_schemes)
      end
    end
  end

  match { |html| find_vectors.call(html).empty? }

  failure_message do |html|
    "expected #{html.inspect} to be free of script vectors, found #{find_vectors.call(html).inspect}"
  end
end
