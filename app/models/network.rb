class Network < ActiveRecord::Base
	#ニューラルネットと教師関数は1:nの関係
	has_many :teachers
	#ニューラルネットワークのタイトルは必須
	validates :title, :presence => true
	validates :input, :presence => true	
	validates :middle, :presence => true	
	validates :output, :presence => true	
	#入力、中間、出力のニューロン数は数値
	validates :input, :numericality => true
	validates :middle, :numericality => true
	validates :output, :numericality => true
	validates_inclusion_of :input, :in=>1..9
	validates_inclusion_of :middle, :in=>1..9
	validates_inclusion_of :output, :in=>1..9
end
