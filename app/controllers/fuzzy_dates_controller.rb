# 日付の欄の入力中に、読み取った結果を文字で返す。規則を JavaScript に写さず、
# FuzzyDate.parse の1か所だけに置くため。
class FuzzyDatesController < ApplicationController
  def show
    value = FuzzyDate.parse(params[:text])
    render plain: FuzzyDate.valid?(value) ? FuzzyDate.label(value) : "読めない"
  end
end
