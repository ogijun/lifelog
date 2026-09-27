# 日付の欄の入力中に、読み取った結果を文字で返す。規則を JavaScript に写さず、
# FuzzyTimestamp.parse (gem) の1か所だけに置くため。
class FuzzyDatesController < ApplicationController
  def show
    value = FuzzyTimestamp.parse(params[:text], now: Time.current)
    render plain: FuzzyTimestamp.valid?(value) ? FuzzyTimestamp.label(value) : "読めない"
  end
end
