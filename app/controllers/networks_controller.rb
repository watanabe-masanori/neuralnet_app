class NetworksController < ApplicationController

	def index
		@networks = Network.all
	end

	def new
		@network = Network.new
	end

	def show
		@network = Network.find(params[:id])
	end

	def create
		@network = Network.new(network_params)
		@network.weight = create_weight(@network.input,@network.middle,@network.output)
		if @network.save
			redirect_to networks_path
		else
			render 'new'
		end
	end

	private
		def network_params
			params[:network].permit(:title,:input,:middle,:output)
		end

		#重みを乱数で作成し、文字列化
		def create_weight(input,middle,output)
			strTmp = ""
			#入力層-中間層の重みを作成
			for numMiddle in 1..middle do 
				for numInput in 1..input do
					if numInput==1 && numMiddle==1 
						strTmp = rand2
					else
						strTmp = strTmp + "," + rand2
					end
				end
			end
			#スプリッタの挿入
			strTmp = strTmp + ";"
			#中間層-出力層の重みを作成
			for numOutput in 1..output do 
				for numMiddle in 1..middle do
					if numMiddle==1 && numOutput==1 
						strTmp = strTmp + rand2
					else
						strTmp = strTmp + "," + rand2
					end
				end
			end
			return strTmp;
		end
		
		#-0.5～0.5までの乱数文字列を発生
		def rand2
			return ((rand-0.5).round(2)).to_s
		end
end
