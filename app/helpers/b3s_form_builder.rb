# encoding: utf-8
# frozen_string_literal: true

class B3SFormBuilder < ActionView::Helpers::FormBuilder
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::OutputSafetyHelper

  def errors_on?(attribute)
    errors_on(attribute).any?
  end

  def errors_on(attribute)
    errors = object.errors[attribute] || []
    Array(errors)
  end

  def first_error(attribute)
    errors_on(attribute).first
  end

  def label(method, text = nil, options = {}, &)
    output = [text || human_attribute_name(method)]
    if errors_on?(method)
      output << tag.span(" #{first_error(method)}", class: "error")
    elsif options[:description]
      output << tag.span(safe_join([" – ", options[:description]], ""),
                         class: "description")
    end
    tag.label(safe_join(output), for: full_attribute_name(method))
  end

  def field_with_label(attr, content, label_text = nil, opts = {})
    classes = ["field"]
    classes << "field_with_errors" if errors_on?(attr)

    label_tag = label(attr, label_text, description: opts[:description])
    content = safe_join([content, opts[:note]], tag(:br)) if opts[:note]

    tag.p(safe_join([label_tag, content]), class: classes.join(" "))
  end

  def labelled_text_field(attribute, label_text = nil, options = {})
    labelled_field(:text_field, attribute, label_text, options)
  end

  def labelled_text_area(attribute, label_text = nil, options = {})
    labelled_field(:text_area, attribute, label_text, options)
  end

  def labelled_date_select(attribute, label_text = nil, options = {})
    labelled_field(:date_select, attribute, label_text, options)
  end

  def labelled_datetime_select(attribute, label_text = nil, options = {})
    labelled_field(:datetime_select, attribute, label_text, options)
  end

  def labelled_time_select(attribute, label_text = nil, options = {})
    labelled_field(:time_select, attribute, label_text, options)
  end

  def labelled_file_field(attribute, label_text = nil, options = {})
    labelled_field(:file_field, attribute, label_text, options)
  end

  def labelled_password_field(attribute, label_text = nil, options = {})
    labelled_field(:password_field, attribute, label_text, options)
  end

  def labelled_time_zone_select(attr, label = nil, priority = nil, opts = {})
    label, opts, field_opts = parse_label_and_opts(label, opts)
    field_with_label(attr, time_zone_select(attr, priority, opts),
                     label, field_opts)
  end

  def labelled_select(attr, choices, label = nil, opts = {})
    label, opts, field_opts = parse_label_and_opts(label, opts)
    field_with_label(attr, select(attr, choices, opts), label, field_opts)
  end

  # rubocop:disable Metrics/ParameterLists

  def labelled_check_box(attr, label = nil, options = {},
                         checked = "1", unchecked = "0")
    label, options, field_options = parse_label_and_opts(label, options)
    field_with_label(attr, check_box(attr, options, checked, unchecked),
                     label, field_options)
  end

  # rubocop:enable Metrics/ParameterLists

  private

  def extract_field_options(options)
    field_options = options.extract!(:description, :note)
    [options, field_options]
  end

  def full_attribute_name(attribute)
    [object.class.to_s.underscore, attribute].join("_")
  end

  def human_attribute_name(attribute)
    object.class.human_attribute_name(attribute)
  end

  def labelled_field(type, attribute, label_text = nil, options = {})
    label_text, options, field_options = parse_label_and_opts(label_text,
                                                              options)
    field_with_label(attribute, send(type, attribute, options),
                     label_text, field_options)
  end

  def parse_label_and_opts(label_text = nil, options = {})
    if label_text.is_a?(Hash) && options == {}
      options = label_text
      label_text = nil
    end
    [label_text, *extract_field_options(options)]
  end
end
