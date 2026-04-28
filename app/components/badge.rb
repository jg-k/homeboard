class Badge < Phlex::HTML
  def initialize(color = nil, size: :sm, **attrs)
    @color = color
    @size = size
    @attrs = attrs
  end

  def view_template(&)
    classes = [ "badge" ]
    classes << "badge-#{@size}" unless @size == :base
    classes << "badge-#{@color}" if @color
    classes << @attrs.delete(:class) if @attrs[:class]
    span(class: classes.join(" "), **@attrs, &)
  end
end
