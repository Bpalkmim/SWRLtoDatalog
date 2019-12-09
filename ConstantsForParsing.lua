-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-- Arquivo: ConstantsForParsing.lua
-- Autor: Bernardo Alkmim (bpalkmim@gmail.com)
--
-- Um módulo Lua que contém constantes úteis tanto para o frontend quanto para o backend.
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------



local lpeg = require "lpeg"

-- Define o módulo
ConstantsForParsing = {}

-- Tags para a AST.
local tag = {}
tag["root"] 		= "Root"
tag["URIreference"]	= "URIreference"
tag["annotations"]	= "Annotations"
tag["annotation"]	= "Annotation"
tag["implication"]	= "Implication"
tag["antecedent"]	= "Antecedent"
tag["consequent"]	= "Consequent"
tag["atoms"]		= "Atoms"
tag["atom"]			= "Atom"
tag["sameAs"]		= "Same As"
tag["differentFrom"]= "Different From"
tag["builtIn"]		= "Built In"
tag["litString"]	= "LitString"
tag["number"]		= "Number"
tag["var"]			= "Variable"
tag["id"] 			= "Identifier"

function ConstantsForParsing.getTag()
	return tag
end

-- Palavras-chave.
local kw = {}
kw["sameAs"] 		= lpeg.P("sameAs")
kw["differentFrom"] = lpeg.P("differentFrom")
kw["builtIn"]		= lpeg.P("buildIn")

function ConstantsForParsing.getKw()
	return kw
end