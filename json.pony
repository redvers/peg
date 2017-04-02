primitive JsonParser
  fun apply(): Parser =>
    let obj = Forward
    let array = Forward

    let digit19 = R('1', '9')
    let digit = R('0', '9')
    let digits = digit.many1()
    let int =
      (L("-") * digit19 * digits) /
      (L("-") * digit) /
      (digit19 * digits) /
      (digit)
    let frac = L(".") * digits
    let exp = (L("e") / L("E")) * (L("+") / L("-")).opt() * digits
    let number = (int * frac.opt() * exp.opt()).term()

    let hex = digit / R('a', 'f') / R('A', 'F')
    let char =
      L("\\\"") / L("\\\\") / L("\\/") / L("\\b") / L("\\f") / L("\\n") /
      L("\\r") / L("\\t") / (L("\\u") * hex * hex * hex * hex) /
      (not L("\"") * not L("\\") * R(' '))

    // TODO: labels
    // TODO: get the shape of the parse tree right
    let string = (L("\"") * char.many() * L("\"")).term()
    let value =
      L("null") / L("true") / L("false") / number / string / obj / array

    let pair = string * L(":").skip() * value
    let members = (pair * (L(",").skip() * pair).many()).opt()
    let elements = (value * (L(",").skip() * value).many()).opt()

    obj() = L("{").skip() * members * L("}").skip()
    array() = L("[").skip() * elements * L("]").skip()

    let whitespace = (L(" ") / L("\t") / L("\r") / L("\n")).many1()
    let linecomment = (L("//") * (not L("\r") * not L("\n") * Unicode).many())
    let nestedcomment = Forward
    nestedcomment() =
      L("/*") *
      ((not L("/*") * not L("*/") * Unicode) / nestedcomment).many() *
      L("*/")
    let hidden = (whitespace / linecomment / nestedcomment).many()

    value.hide(hidden)
