module ApplicationHelper
  def amt(v)
    n = v.to_i
    n.negative? ? "▲ #{number_with_delimiter(n.abs)}" : number_with_delimiter(n)
  end
end
