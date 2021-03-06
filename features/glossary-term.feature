Feature: @glossary -> @term
  Scenario Outline: Define an @term with an explicit @description
    Given I have defined a valid glossary named <glossary>
    And I define a term named <term> with value <value> and description <description>
    When I get the result hash
    Then the glossary <glossary> should contain a term named <term>
    And the term <term> of glossary <glossary> should have value <value>
    And the term <term> of glossary <glossary> should have description <description>

    Examples:
    | glossary        | term        | value     | description                               |
    | SomeGlossary    | SomeTerm    | SomeValue | I am a description                        |
    | AnotherGlossary | AnotherTerm | AValue    | I am a silly description with a silly hat |

  Scenario Outline: Define an @term with no description
    Given I have defined a valid glossary named TestGlossary
    And I define a term named <name> with value <value>
    But I don't give it a description
    When I get the result hash
    Then the glossary TestGlossary should contain a term named <name>
    And the term <name> of glossary TestGlossary should have value <value>

    Examples:
    | name        | value        |
    | ATerm       | AValue       |
    | AnotherTerm | AnotherValue |

  Scenario: Define an @term with no name
    Given I have defined a valid glossary
    And I define a term
    But I don't give it a name
    When I get the result hash
    Then there should be a parse error

  Scenario Outline: Define an @term with no value
    Given I have defined a valid glossary named TestGlossary
    And I define a term named <name>
    But I don't give it a name
    When I get the result hash
    Then the glossary TestGlossary should contain a term named <name>
    And the term <name> of glossary TestGlossary should have value <name>

    Examples:
    | name        |
    | ATerm       |
    | AnotherTerm |
