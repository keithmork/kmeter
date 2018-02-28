// JMeter built-ins：args[]

def varName = args[1]

if (varName == null) {
    throw RuntimeException('[Error] Variable name cannot be empty!')
}

if (vars.get(varName) == null) {
    throw RuntimeException('[Error] No such variable: ' + varName)
} else {
    props.put(varName, vars.get(varName))
}
