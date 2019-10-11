[
  inputs: [
    "{mix,.formatter}.exs",
    "{bench,config,lib,old,test}/**/*.{ex,exs}"
  ],
  locals_without_parens: [defsieve: 2, defsieve: 3],
  export: [
    locals_without_parens: [defsieve: 2, defsieve: 3]
  ]
]
