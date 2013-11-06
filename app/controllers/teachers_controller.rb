class TeachersController < ApplicationController
	def create
		@network = Network.find(params[:network_id])
		@teacher = @network.teachers.create(teacher_params)
		redirect_to network_path(@network.id)
	end

	def show
		@network = Network.find(params[:network_id])
		@teacher = Teacher.find(params[:id])
		@output = calc_network_output
	end

	def destroy
		@teacher = Teacher.find(params[:id])
		@teacher.destroy
		redirect_to network_path(params[:network_id])
	end

	private
		def teacher_params
			params[:teacher].permit(:data)
		end

		#ニューラルネットワークに信号を入れて、出力を得る関数
		def calc_network_output
			inputArray = @teacher.data.split(",")
			iInput = @network.input
			iMiddle = @network.middle
			iOutput = @network.output
			dMiddleArray = []
			dOutputArray = []
			#ルビーは複数配列を引数で渡せないので、重みをハッシュで渡す
			#(1)入力値をニューラルネットに反映させ、中間層のニューロンへの入力値を計算
			hashWeight = create_weight_hash(0, iInput, iMiddle)
			for i in 0..(iMiddle - 1) do 
				dMiddleArray[i] = (calc_neuron_output(iInput, i, hashWeight, *inputArray)).to_s
			end
			#(2)中間層の出力値から、出力層の出力値を計算
			hashWeight = create_weight_hash(1, iMiddle, iOutput)
			for i in 0..(iOutput - 1) do 
				dOutputArray[i] = (calc_neuron_output(iMiddle, i, hashWeight, *dMiddleArray)).to_s
			end
			return dOutputArray.join(",")
		end
		
		#重みをハッシュに登録する
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

		#ニューロン出力値の計算
		def calc_neuron_output(iPreNeuronNum, iIndex, hashWeight = {}, *dInputArray)
			dInput = 0.0
			strKey = ""
			for i in 0..(iPreNeuronNum-1)  do
				strKey = "W" +  i.to_s + iIndex.to_s
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
end
