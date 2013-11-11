require 'logger'

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

	def edit
		@network = Network.find(params[:id])
		#このニューラルネットに対応する教師関数のみを取得する
		@teachers = Teacher.where(network_id: params[:id])
		#教師関数を使い学習し、重みの更新
		@output = study
		@network.weight = @output
		@network.save

		#一覧画面にリダイレクト
		#redirect_to networks_path
	end

	def create
		@network = Network.new(network_params)
		if !@network.input.nil? && !@network.middle.nil? && !@network.output.nil? 
			@network.weight = create_weight(@network.input,@network.middle,@network.output)
		end
		if @network.save
			redirect_to networks_path
		else
			render 'new'
		end
	end

	def destroy
		@network = Network.find(params[:id])
		@network.destroy
		redirect_to networks_path
	end

	private
		def network_params
			params[:network].permit(:title,:input,:middle,:output)
		end

		#ニューラルネットワークに信号を入れて、出力を得る関数(重複関数、DRYに反する、要修正)
		def calc_network_output(teacherStr,hashMiddleWeight={},hashOutputWeight={})
			log = Logger.new(STDOUT)
			inputArray = teacherStr.split(",")
			iInput = @network.input
			iMiddle = @network.middle
			iOutput = @network.output
			dMiddleArray = []
			dOutputArray = []
			hashResult = {}
			#ルビーは複数配列を引数で渡せないので、重みをハッシュで渡す
			#(1)入力値をニューラルネットに反映させ、中間層のニューロンへの入力値を計算
			#hashWeight = create_weight_hash(0, iInput, iMiddle)
			for i in 0..(iMiddle - 1) do 
				dMiddleArray[i] = (calc_neuron_output(iInput, i, hashMiddleWeight, *inputArray)).to_s
				hashResult["M" + i.to_s] = dMiddleArray[i]
			end
			#(2)中間層の出力値から、出力層の出力値を計算
			#hashWeight = create_weight_hash(1, iMiddle, iOutput)
			for i in 0..(iOutput - 1) do 
				dOutputArray[i] = (calc_neuron_output(iMiddle, i, hashOutputWeight, *dMiddleArray)).to_s
				hashResult["O" + i.to_s] = dOutputArray[i]
			end
			return hashResult
		end

		#重みをハッシュに登録する(重複関数、DRYに反する、要修正)
		def create_weight_hash(iLayer, num1, num2)
			hashWeight = {}

			weightArray = (@network.weight.split(";"))[iLayer].split(",")
			iCount = 0
			for j in 0..(num2-1) do 
				for i in 0..(num1-1) do
					strKey = "W" + i.to_s + j.to_s
					hashWeight[strKey] = weightArray[iCount]
					iCount += 1
				end
			end
			return hashWeight
		end

		def concat_data(*data)
			strTmp = ""
			data.each{ |var|
				strTmp = strTmp + "," + var
			}
			return strTmp
		end	

		#ニューロン出力値の計算(重複関数、DRYに反する、要修正)
		def calc_neuron_output(iPreNeuronNum, iIndex, hashWeight = {}, *dInputArray)
			log = Logger.new(STDOUT)
			dInput = 0.0
			strKey = ""
			for i in 0..(iPreNeuronNum-1)  do
				strKey = "W" +  i.to_s + iIndex.to_s
				#log.debug(iPreNeuronNum.to_s + strKey)
				dInput += dInputArray[i].to_f * hashWeight[strKey].to_f
			end
			return calc_neuron_output_sub(dInput)
		end
		def calc_neuron_output_sub(dInput)
			#伝達関数（シグモイド関数）により出力値を決定する。
			#シグモイド関数は、1/(1+e^(-ax))とする。aはゲイン
			dGain = 0.1
			return 1.0 / (1.0 + Math.exp(-1.0 * dGain * dInput))
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
			return ((rand-0.5).round(4)).to_s
		end

		#教師信号を使って、学習する関数
		def study()
			log = Logger.new(STDOUT)
			
			dAlpha = 1 #学習係数
			@dError = 0
			iInput = @network.input
			iMiddle = @network.middle
			iOutput = @network.output

			teacherArray = []	#教師信号の一時変数
			resultArray = []		#出力信号の一時変数
			dOutputD = []		#出力ニューロンの誤差伝搬値
			dMiddleD = []		#中間ニューロンの誤差伝搬値
			hashOutputW = {}		#出力層の修正後の重み
			hashMiddleW = {}		#中間層の修正後の重み
			hashResult = {}		#全ニューロンの出力結果
			hashDelta = {}		#全ニューロンの逆誤差伝搬の値

			#重みハッシュの作成
			hashMiddleW = create_weight_hash(0, iInput, iMiddle)
			hashOutputW = create_weight_hash(1, iMiddle, iOutput)
			dTmp = 0
			#現状、早く処理を返すため、1000回の学習とする
			for i in 0..1000 do
				#すべての教師関数に対して学習
				@teachers.each{ |elem|
					#(1)出力の計算
					teacherArray = elem.data.split(",")
					hashResult = calc_network_output(elem.data,hashMiddleW,hashOutputW)
					#(2)誤差の計算
					@dError = 0
					for i in 0..(iOutput - 1 ) do 
						strKey = "O" + i.to_s
						dTmp = hashResult[strKey].to_f
						@dError += (teacherArray[iInput + i].to_f - dTmp) * (teacherArray[iInput + i].to_f - dTmp)
					end

					#(3)出力層の結合度の修正
					for i in 0..(iOutput - 1 ) do 
						for j in 0..(iMiddle - 1 ) do
							strKeyO = "O" + i.to_s
							strKeyM = "M" + j.to_s
							strKeyW = "W" +  j.to_s + i.to_s
							#出力層の該当ニューロンの出力値をハッシュから取得
							dOutput = hashResult[strKeyO].to_f
							#中間層の該当ニューロンの出力値をハッシュから取得
							dMiddle =  hashResult[strKeyM].to_f
							#逆誤差伝搬の値を計算
							hashDelta[strKeyO] = (teacherArray[iInput + i].to_f - dOutput ) * dOutput * (1 - dOutput)
							#便宜上、学習係数は、定数とし、重みの修正
							hashOutputW[strKeyW] = (hashOutputW[strKeyW].to_f + (dAlpha * dMiddle * hashDelta[strKeyO].to_f)).to_s
						end
					end
					#(4)中間層の結合度の修正
					for i in 0..(iMiddle - 1 ) do 
						for j in 0..(iInput - 1 ) do
							dTmp = 0
							for k in 0..(iOutput - 1 ) do
								#重みをハッシュから取得
								strKeyW = "W" +  i.to_s + k.to_s
								dTmpWeight = hashOutputW[strKeyW].to_f
								#以前計算した逆誤差伝搬の値をハッシュから取得
								strKeyO = "O" + k.to_s
								dTmpDelta = hashDelta[strKeyO]
								#中間層のニューロンの逆誤差伝搬の値を計算
								dTmp += dTmpWeight * dTmpDelta
							end
							strKeyW = "W" +  j.to_s + i.to_s
							strKeyM = "M" + i.to_s
							#中間層の該当ニューロンの出力値をハッシュから取得
							dMiddle =  hashResult[strKeyM].to_f
							#便宜上、学習係数は、定数とし、重みの修正
							hashMiddleW[strKeyW] = (hashMiddleW[strKeyW].to_f + (dAlpha * teacherArray[j].to_f * dMiddle * ( 1 - dMiddle ) * dTmp)).to_s
						end
					end
				}
				log.debug(@dError)
			end
			#最後に重みを文字列形式にして返す
			strTmp = ""
			#入力層-中間層の重みを作成
			for j in 0..(iMiddle - 1)  do 
				for i in 0..(iInput - 1) do
					strKeyW = "W" + i.to_s + j.to_s
					if i==0 && j==0
						strTmp = hashMiddleW[strKeyW].to_f.round(4).to_s
					else
						strTmp = strTmp + "," + hashMiddleW[strKeyW].to_f.round(4).to_s
					end
				end
			end
			#スプリッタの挿入
			strTmp = strTmp + ";"
			#中間層-出力層の重みを作成
			for j in 0..(iOutput - 1) do 
				for i in 0..(iMiddle - 1) do
					strKeyW = "W" + i.to_s + j.to_s
					if i==0 && j==0 
						strTmp = strTmp + hashOutputW[strKeyW].to_f.round(4).to_s
					else
						strTmp = strTmp + "," + hashOutputW[strKeyW].to_f.round(4).to_s
					end
				end
			end
			@dError = @dError.round(8)
			return strTmp;			

			#return hashMiddleW #@teachers[0].data.split(",")		
		end
end
