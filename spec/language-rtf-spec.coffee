describe "language-rtf", ->
  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage "language-rtf"

  describe "RTF grammar", ->
    grammar = undefined

    beforeEach ->
      grammar = atom.grammars.grammarForScopeName "text.rtf"

    it "is defined", ->
      expect(grammar.scopeName).toBe "text.rtf"

    it "tokenizes groups", ->
      {tokens} = grammar.tokenizeLine "{}{\\*\\foo}"
      expect(tokens.length).toBe 5
      expect(tokens[0]).toEqual value: "{", scopes: ["text.rtf", "keyword.operator.begin-group.rtf"]
      expect(tokens[1]).toEqual value: "}", scopes: ["text.rtf", "keyword.operator.end-group.rtf"]
      expect(tokens[2]).toEqual value: "{\\*", scopes: ["text.rtf", "keyword.operator.begin-ignorable-destination-group.rtf"]
      expect(tokens[3]).toEqual value: "\\foo", scopes: ["text.rtf", "support.function.rtf"]
      expect(tokens[4]).toEqual value: "}", scopes: ["text.rtf", "keyword.operator.end-ignorable-destination-group.rtf"]

    it "tokenizes control symbols", ->
      {tokens} = grammar.tokenizeLine "\\\\\\{\\}\\|\\~\\-\\_\\:\\'a0\\!"
      expect(tokens.length).toBe 10
      expect(tokens[0]).toEqual value: "\\\\", scopes: ["text.rtf", "constant.character.escape.rtf"]
      expect(tokens[1]).toEqual value: "\\{", scopes: ["text.rtf", "constant.character.escape.rtf"]
      expect(tokens[2]).toEqual value: "\\}", scopes: ["text.rtf", "constant.character.escape.rtf"]
      expect(tokens[3]).toEqual value: "\\|", scopes: ["text.rtf", "keyword.operator.formula.rtf"]
      expect(tokens[4]).toEqual value: "\\~", scopes: ["text.rtf", "constant.character.escape.non-breaking-space.rtf"]
      expect(tokens[5]).toEqual value: "\\-", scopes: ["text.rtf", "constant.character.escape.optional-hyphen.rtf"]
      expect(tokens[6]).toEqual value: "\\_", scopes: ["text.rtf", "constant.character.escape.non-breaking-hyphen.rtf"]
      expect(tokens[7]).toEqual value: "\\:", scopes: ["text.rtf", "keyword.operator.index-subentry.rtf"]
      expect(tokens[8]).toEqual value: "\\'a0", scopes: ["text.rtf", "constant.character.escape.hexadecimal.rtf"]
      expect(tokens[9]).toEqual value: "\\!", scopes: ["text.rtf", "invalid.unimplemented.rtf"]

    it "tokenizes document", ->
      # From https://en.wikipedia.org/wiki/Rich_Text_Format#Code_syntax
      lines = grammar.tokenizeLines """
        {\\rtf1\\ansi{\\fonttbl\\f0\\fswiss Helvetica;}\\f0\\pard
        This is some {\\b bold} text.\\par
        }
      """
      tokens = lines[0]
      expect(tokens.length).toBe 14
      expect(tokens[0]).toEqual value: "{", scopes: ["text.rtf", "keyword.operator.begin-group.rtf"]
      expect(tokens[1]).toEqual value: "\\rtf", scopes: ["text.rtf", "support.function.rtf"]
      expect(tokens[2]).toEqual value: "1", scopes: ["text.rtf", "constant.numeric.rtf"]
      expect(tokens[3]).toEqual value: "\\ansi", scopes: ["text.rtf", "support.function.rtf"]
      expect(tokens[4]).toEqual value: "{", scopes: ["text.rtf", "keyword.operator.begin-group.rtf"]
      expect(tokens[5]).toEqual value: "\\fonttbl", scopes: ["text.rtf", "support.function.rtf"]
      expect(tokens[6]).toEqual value: "\\f", scopes: ["text.rtf", "support.function.rtf"]
      expect(tokens[7]).toEqual value: "0", scopes: ["text.rtf", "constant.numeric.rtf"]
      expect(tokens[8]).toEqual value: "\\fswiss", scopes: ["text.rtf", "support.function.rtf"]
      expect(tokens[9]).toEqual value: " Helvetica;", scopes: ["text.rtf"]
      expect(tokens[10]).toEqual value: "}", scopes: ["text.rtf", "keyword.operator.end-group.rtf"]
      expect(tokens[11]).toEqual value: "\\f", scopes: ["text.rtf", "support.function.rtf"]
      expect(tokens[12]).toEqual value: "0", scopes: ["text.rtf", "constant.numeric.rtf"]
      expect(tokens[13]).toEqual value: "\\pard", scopes: ["text.rtf", "support.function.rtf"]
      tokens = lines[1]
      expect(tokens.length).toBe 7
      expect(tokens[0]).toEqual value: "This is some ", scopes: ["text.rtf"]
      expect(tokens[1]).toEqual value: "{", scopes: ["text.rtf", "keyword.operator.begin-group.rtf"]
      expect(tokens[2]).toEqual value: "\\b", scopes: ["text.rtf", "support.function.rtf"]
      expect(tokens[3]).toEqual value: " bold", scopes: ["text.rtf", "markup.bold.rtf"]
      expect(tokens[4]).toEqual value: "}", scopes: ["text.rtf", "keyword.operator.end-group.rtf"]
      expect(tokens[5]).toEqual value: " text.", scopes: ["text.rtf"]
      expect(tokens[6]).toEqual value: "\\par", scopes: ["text.rtf", "support.function.rtf"]
      tokens = lines[2]
      expect(tokens.length).toBe 1
      expect(tokens[0]).toEqual value: "}", scopes: ["text.rtf", "keyword.operator.end-group.rtf"]

    it "tokenizes property changes", ->
      # From page 250 of the RTF specification v1.9.1
      # <https://www.microsoft.com/en-us/download/details.aspx?id=10725>
      lines = grammar.tokenizeLines """
        {\\b bold \\i Bold Italic \\i0 Bold again}
        {\\b bold {\\i Bold Italic }Bold again}
        {\\b bold \\i Bold Italic \\plain\\b Bold again}
      """
      tokens = lines[0]
      expect(tokens.length).toBe 9
      expect(tokens[0]).toEqual value: "{", scopes: ["text.rtf", "keyword.operator.begin-group.rtf"]
      expect(tokens[1]).toEqual value: "\\b", scopes: ["text.rtf", "support.function.rtf"]
      expect(tokens[2]).toEqual value: " bold ", scopes: ["text.rtf", "markup.bold.rtf"]
      expect(tokens[3]).toEqual value: "\\i", scopes: ["text.rtf", "markup.bold.rtf", "support.function.rtf"]
      expect(tokens[4]).toEqual value: " Bold Italic ", scopes: ["text.rtf", "markup.bold.rtf", "markup.italic.rtf"]
      expect(tokens[5]).toEqual value: "\\i", scopes: ["text.rtf", "markup.bold.rtf", "support.function.rtf"]
      expect(tokens[6]).toEqual value: "0", scopes: ["text.rtf", "markup.bold.rtf", "constant.numeric.rtf"]
      expect(tokens[7]).toEqual value: " Bold again", scopes: ["text.rtf", "markup.bold.rtf"]
      expect(tokens[8]).toEqual value: "}", scopes: ["text.rtf", "keyword.operator.end-group.rtf"]
      tokens = lines[1]
      expect(tokens.length).toBe 9
      expect(tokens[0]).toEqual value: "{", scopes: ["text.rtf", "keyword.operator.begin-group.rtf"]
      expect(tokens[1]).toEqual value: "\\b", scopes: ["text.rtf", "support.function.rtf"]
      expect(tokens[2]).toEqual value: " bold ", scopes: ["text.rtf", "markup.bold.rtf"]
      expect(tokens[3]).toEqual value: "{", scopes: ["text.rtf", "markup.bold.rtf", "keyword.operator.begin-group.rtf"]
      expect(tokens[4]).toEqual value: "\\i", scopes: ["text.rtf", "markup.bold.rtf", "support.function.rtf"]
      expect(tokens[5]).toEqual value: " Bold Italic ", scopes: ["text.rtf", "markup.bold.rtf", "markup.italic.rtf"]
      expect(tokens[6]).toEqual value: "}", scopes: ["text.rtf", "markup.bold.rtf", "keyword.operator.end-group.rtf"]
      expect(tokens[7]).toEqual value: "Bold again", scopes: ["text.rtf", "markup.bold.rtf"]
      expect(tokens[8]).toEqual value: "}", scopes: ["text.rtf", "keyword.operator.end-group.rtf"]
      tokens = lines[2]
      expect(tokens.length).toBe 9
      expect(tokens[0]).toEqual value: "{", scopes: ["text.rtf", "keyword.operator.begin-group.rtf"]
      expect(tokens[1]).toEqual value: "\\b", scopes: ["text.rtf", "support.function.rtf"]
      expect(tokens[2]).toEqual value: " bold ", scopes: ["text.rtf", "markup.bold.rtf"]
      expect(tokens[3]).toEqual value: "\\i", scopes: ["text.rtf", "markup.bold.rtf", "support.function.rtf"]
      expect(tokens[4]).toEqual value: " Bold Italic ", scopes: ["text.rtf", "markup.bold.rtf", "markup.italic.rtf"]
      expect(tokens[5]).toEqual value: "\\plain", scopes: ["text.rtf", "support.function.rtf"]
      expect(tokens[6]).toEqual value: "\\b", scopes: ["text.rtf", "support.function.rtf"]
      expect(tokens[7]).toEqual value: " Bold again", scopes: ["text.rtf", "markup.bold.rtf"]
      expect(tokens[8]).toEqual value: "}", scopes: ["text.rtf", "keyword.operator.end-group.rtf"]
