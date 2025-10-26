module ApplicationHelper
  def amt(n)
    n = n.to_i
    s = number_with_delimiter(n.abs)
    n.negative? ? "-#{s}" : s
  end
end
