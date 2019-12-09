-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- Arquivo: ParseSWRL.lua
-- Autor: Bernardo Alkmim (bpalkmim@gmail.com)
--
-- Um módulo Lua para parsear sentenças em SWRL, gerando uma AST em forma de tabela.
-- É necessário ter o pacote lpeg. Recomendo a instalação via Luarocks.
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

local lpeg = require "lpeg"
require "ConstantsForParsing"

-- Define o módulo
ParseSWRL = {}

-------------------------------------------------------------------------------------------
-- Definições iniciais
-------------------------------------------------------------------------------------------

-- Variáveis auxiliares para as funções do módulo
local indent = 0
local tabs = ""

-- Strings auxiliares
local errConversion = "Erro de conversão de tabela para string."

-- Tags para a AST.
local tag = ConstantsForParsing.getTag()

-- Elementos Léxicos.
local space 	= lpeg.S(" \n\t")
local skip 		= space^0
local upper 	= lpeg.R("AZ")
local lower 	= lpeg.R("az")
local letter 	= upper + lower

local digit 		= lpeg.R("09")
local integer 		= lpeg.S("-")^-1 * digit^1
local fractional 	= lpeg.P(".") * digit^1
local decimal 		= integer * fractional^-1 + lpeg.S("+-") * fractional
local scientific 	= decimal * lpeg.S("Ee") * integer
local number 		= decimal + scientific

-- Adicionado o : aos identificadores
local id 			= (lpeg.P("_") + letter) * (lpeg.S("_-:") + letter + digit)^0
local quotedId 		= lpeg.P("\"") * (lpeg.P("\\") * lpeg.P(1) + (1 - lpeg.S("\\\"")))^0 * lpeg.P("\"")
local identifier 	= id + quotedId

local literalString = lpeg.P("'") * (lpeg.P("\\") * lpeg.P(1) + (1 - (lpeg.S("\\'") + lpeg.S("''"))))^0 * lpeg.P("'")

-- Operadores
local compOperator 	= lpeg.C(lpeg.P(">="))
	+ lpeg.C(lpeg.P("<="))
	+ lpeg.C(lpeg.P("!="))
	+ lpeg.C(lpeg.P("<>"))
	+ lpeg.C(lpeg.P(">"))
	+ lpeg.C(lpeg.P("<"))
	+ lpeg.C(lpeg.P("="))
local addOperator 	= lpeg.C(lpeg.P("+"))
	+ lpeg.C(lpeg.P("-"))
local multOperator 	= lpeg.C(lpeg.P("*"))
	+ lpeg.C(lpeg.P("/"))
	+ lpeg.C(lpeg.P("%"))

-- Palavras-chave.
local kw = ConstantsForParsing.getKw()

-- Atualização de identifier com as keywords
local keyWords 		= lpeg.S("")
for k, _ in pairs(kw) do
	keyWords = keyWords + (kw[k] * -(letter + digit + lpeg.S("_-")))
end
identifier 			= identifier - keyWords

-- Variáveis (precedidas por ?)
local variable		= lpeg.P("?") * identifier

-------------------------------------------------------------------------------------------
-- Funções locais auxiliares ao módulo
-------------------------------------------------------------------------------------------

-- Função que passa o conteúdo de um arquivo para um string.
local function getContents(fileName)
	local file = assert(io.open(fileName, "r"))
	local contents = file:read("*a")
	file:close()
	return contents
end

-- Função de tageamento de captura.
local function taggedCap(tagging, pat)
	return lpeg.Ct(lpeg.Cg(lpeg.Cc(tagging), "tag") * pat)
end

-- Função que retorna a definição da gramática da entrada.
local function getGrammar()
	-- Preâmbulo: definições dos termos utilizados dentro da gramática.
	-- Parte essencialmente burocrática.
	local rules, rule = lpeg.V("rules"), lpeg.V("rule")
	local URIreference, annotations, annotation =
		lpeg.V("URIreference"), lpeg.V("annotations"), lpeg.V("annotation")
	local implication, antecedent, consequent =
		lpeg.V("implication"), lpeg.V("antecedent"), lpeg.V("consequent")
	local atoms, atom = lpeg.V("atoms"), lpeg.V("atom")
	local sameAs, differentFrom, builtIn =
		lpeg.V("sameAs"), lpeg.V("differentFrom"), lpeg.V("builtIn")
	local parameters = lpeg.V("parameters")
	local ident, var = lpeg.V("ident"), lpeg.V("var")
	local litString = lpeg.V("litString")

	-- Definição da gramática em si.
	local grammar = lpeg.P{
		rules,
		rules = taggedCap(tag["root"],
			URIreference^-1 * skip * annotations^-1 *
				((skip * rule)^1 * skip * -1)
				+ skip * rule * skip * -1);
		rule = taggedCap(tag["rule"],
			implication
			+ atom);

		-- Composição básica de uma regra
		URIreference = taggedCap(tag["URIreference"], litString);
		annotations = taggedCap(tag["annotations"],
			(skip * annotation)^1);
		annotation = taggedCap(tag["annotation"], litString);
		implication = taggedCap(tag["implication"],
			antecedent * skip * lpeg.P("->") * skip * consequent);

		-- Composição de uma implicação
		antecedent = taggedCap(tag["antecedent"], atoms);
		consequent = taggedCap(tag["consequent"], atoms);
		atoms = taggedCap(tag["atoms"],
			(skip * atom * skip * lpeg.P("^"))^0 * skip * atom);

		-- Um átomo da linguagem
		atom = taggedCap(tag["atom"],
			sameAs + differentFrom + builtIn
			+ ident * skip * lpeg.P("(") * parameters * lpeg.P(")"));
		sameAs = taggedCap(tag["sameAs"],
			kw["sameAs"] * skip * lpeg.P("(") * parameters * lpeg.P(")"));
		differentFrom = taggedCap(tag["differentFrom"],
			kw["differentFrom"] * skip * lpeg.P("(") * parameters * lpeg.P(")"));
		builtIn = taggedCap(tag["builtIn"],
			kw["builtIn"] * skip * lpeg.P("(") * parameters * lpeg.P(")"));
		parameters = skip * (ident + var + litString) * skip *
			(lpeg.P(",") * skip * (ident + var + litString) * skip)^0;

		-- TODO limitar sameAs e differentFrom a 2, e ver melhor o builtIn.

		-- Identificadores
		ident = taggedCap(tag["id"], lpeg.C(identifier));
		var = taggedCap(tag["var"], lpeg.C(variable));

		-- Constantes
		litString = taggedCap(tag["litString"], lpeg.C(literalString))
	}

	return grammar
end

-------------------------------------------------------------------------------------------
-- Funções externas do módulo
-------------------------------------------------------------------------------------------

-- Função que parseia a entrada e retorna a árvore de sintaxe abstrata em forma de tabela Lua.
-- Recebe um arquivo com o código SQL.
function ParseSWRL.parseInput(fileName)
	local contents = getContents(fileName)
	local t = lpeg.match(getGrammar(), contents)
	assert(t, "Falha no reconhecimento de "..contents)
	return t
end

-- Função que recebe a AST e retorna sua representação em string.
function ParseSWRL.printAST(ast)

	-- Variável que indica qual o espaço utilizado na representação da AST
	local spacing = "\t"

	if type(ast) == "number" then
		return ast
	elseif type(ast) == "string" then
		return string.format("%s", ast)
	elseif type(ast) == "table" then
		local s = "{ \n"
		indent = indent + 1

		for k, v in pairs(ast) do
			local initTabs = tabs
			for _ = #initTabs, indent-1 do
				tabs = tabs..spacing
			end

			s = s..tabs.."[ "..ParseSWRL.printAST(k).." -> "..ParseSWRL.printAST(v).." ]\n"
			tabs = initTabs
		end

		s = s..tabs.."}"
		tabs = ""
		indent = indent - 1
		return s
	else
		print(errConversion)
	end
end