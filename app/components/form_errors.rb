class FormErrors < Phlex::HTML
  def initialize(record, noun: nil)
    @record = record
    @noun = noun || record.model_name.human.downcase
  end

  def render? = @record.errors.any?

  def view_template
    count = @record.errors.count
    div(class: "form-errors") do
      h2 { "#{count} #{"error".pluralize(count)} prohibited this #{@noun} from being saved:" }
      ul do
        @record.errors.full_messages.each { |message| li { message } }
      end
    end
  end
end
