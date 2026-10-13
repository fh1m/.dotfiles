syntax match rosComment "#.*$"
syntax match rosType "^\s*\zs[a-zA-Z][a-zA-Z0-9_/]*\(\[.*\]\)\?"
syntax match rosSeparator "^---$"
syntax match rosConstant "\<[A-Z][A-Z0-9_]*\>"
highlight default link rosComment Comment
highlight default link rosType Type
highlight default link rosSeparator Delimiter
highlight default link rosConstant Constant
