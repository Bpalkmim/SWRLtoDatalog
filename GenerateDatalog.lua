-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- Arquivo: GenerateDatalog.lua
-- Autor: Bernardo Alkmim (bpalkmim@gmail.com)
--
-- Módulo que gera código Datalog partindo de uma AST de SWRL.
-- É necessário ter o pacote lpeg. Recomendo a instalação via Luarocks.
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

require "ParseSWRL"
require "ConstantsForParsing"

-- Define o módulo.
GenerateDatalog = {}

-- Tags para a AST.
local tag = ConstantsForParsing.getTag()

-- TODO lidar com retrações.

-------------------------------------------------------------------------------------------
-- Funções locais auxiliares ao módulo
-------------------------------------------------------------------------------------------

-- Função que percorre a AST preenchendo a string de saída com o código Datalog de acordo.
local function scanAST(ast)
	-- Parte da saída
	local ret = ""

	-- Auxiliar
	local retAux

	assert(type(ast) == "table", "AST não é uma tabela Lua.")

	if ast["tag"] ~= nil then
		-- TODO ver a questão do . ou ?
		if ast["tag"] == tag["root"] then
			for _, v in ipairs(ast) do
				retAux = scanAST(v)
				ret = ret..retAux
			end

		-- TODO lidar depois com esses caras
		elseif ast["tag"] == tag["URIreference"] then
			ret = ret.."\""..ast[1].."\"\n"

		elseif ast["tag"] == tag["annotations"] then
			for _, v in ipairs(ast) do
				ret = ret..scanAST(v).."\n"
			end

		elseif ast["tag"] == tag["annotation"] then
			ret = ret..ast[1]

		elseif ast["tag"] == tag["implication"] then
			-- Consequente :- Antecedente(s).
			-- Com consequente múltiplo, são realizadas múltiplas regras.
			for _, v in ipairs(ast[2][1]) do
				ret = ret..scanAST(v).." :- "..scanAST(ast[1])..".\n\n"
			end

		elseif ast["tag"] == tag["antecedent"] then
			ret = ret..scanAST(ast[1])

		--[[ Caso do consequente está incluso na implicação.
		elseif ast["tag"] == tag["consequent"] then
			for i, v in ipairs(ast) do
				if i == 1 then
					ret = ret..scanAST(v)
				else
					ret = ret..", "..scanAST(v)
				end
			end]]

		elseif ast["tag"] == tag["atoms"] then
			for i, v in ipairs(ast) do
				if i == 1 then
					ret = ret..scanAST(v)
				else
					ret = ret..", "..scanAST(v)
				end
			end

		elseif ast["tag"] == tag["atom"] then
			ret = ret..scanAST(ast[1]).."("
			for i, v in ipairs(ast) do
				if i == 2 then
					ret = ret..scanAST(v)
				elseif i > 2 then
					ret = ret..", "..scanAST(v)
				end
			end
			ret = ret..")"

		elseif ast["tag"] == tag["sameAs"] then
			-- TODO ver depois como lidar

		elseif ast["tag"] == tag["diferentFrom"] then
			-- TODO ver depois como lidar

		elseif ast["tag"] == tag["builtIn"] then
			-- TODO ver depois como lidar

		elseif ast["tag"] == tag["litString"] then
			ret = ret.."\""..ast[1].."\""

		elseif ast["tag"] == tag["number"] or ast["tag"] == tag["var"] or
				ast["tag"] == tag["id"] then
			ret = ret..ast[1]

		-- TODO demais nós
		else
			for _, v in ipairs(ast) do
				if type(v) == "table" then
					retAux = scanAST(v)
					ret = ret..retAux
				end
			end
		end
	end

	return ret
end

-- Zera as listas auxiliares do módulo e reseta variáveis globais
local function resetModule()
	-- TODO provavelmente só será necessário com a quebra do consequente
	return
end

-- Função que cria um arquivo cujo conteúdo é a string passada por parâmetro, indexando de
-- acordo com o parâmetro passado. O formato do nome é "query_i.swrl"
-- cond pode ser "w" para um arquivo a ser escrito do zero ou "a" para fazer append.
-- Utilizamos append para o caso de haver um Or, que requer várias regras juntas
local function writeToFile(text, i, cond)
	local file = assert(io.open("Output/output_"..i..".datalog", cond))
	file:write(text)
	file:close()
end

-------------------------------------------------------------------------------------------
-- Funções externas do módulo
-------------------------------------------------------------------------------------------

-- Função principal do módulo que recebe um arquivo de um código escrito em SQL, faz sua
-- AST e cria um arquivo em SWRL.
function GenerateDatalog.generateOutput(fileName, index)
	local ast = ParseSWRL.parseInput(fileName)
	writeToFile(scanAST(ast), index, "w")
	resetModule()
end
