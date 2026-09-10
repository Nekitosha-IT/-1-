$ErrorActionPreference = 'Stop'

$EpRoot = Join-Path $PSScriptRoot 'EgaisCancelledTTN2026'
$Module = Join-Path $EpRoot 'Forms\Форма\Ext\Form\Module.bsl'
$Form = Join-Path $EpRoot 'Forms\Форма\Ext\Form.xml'

if (!(Test-Path -LiteralPath $Module)) { throw "Module not found: $Module" }
if (!(Test-Path -LiteralPath $Form)) { throw "Form XML not found: $Form" }

function Decode([string]$s) {
    [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($s))
}

$m = Get-Content -LiteralPath $Module -Raw -Encoding UTF8

# Remove the UTM Accept header without putting Cyrillic into the PowerShell source.
$accept = Decode '0JfQsNC/0YDQvtGBLtCX0LDQs9C+0LvQvtCy0LrQuC7QktGB0YLQsNCy0LjRgtGMKCJBY2NlcHQiLCAiYXBwbGljYXRpb24veG1sIik7'
$m = $m -replace '(?m)^\s*' + [regex]::Escape($accept) + '\s*\r?\n', ''

# Add the three client handlers once. Their BSL is stored as UTF-8 base64 so this .ps1 remains ASCII-safe.
if ($m -notmatch '(?m)^Процедура SelectUTM\(') {
    $marker = Decode 'JtCd0LDQmtC70LjQtdC90YLQtQrQn9GA0L7RhtC10LTRg9GA0LAg0J/QvtC70YPRh9C40YLRjNCU0LDQvdC90YvQtdCY0LfQo9Ci0Jw='
    $pos = $m.IndexOf($marker)
    if ($pos -lt 0) { throw 'Cannot find ПолучитьДанныеИзУТМ procedure.' }
    $insert = Decode 'CibQndCw0JrQu9C40LXQvdGC0LUK0J/RgNC+0YbQtdC00YPRgNCwIFNlbGVjdFVUTSjQmtC+0LzQsNC90LTQsCkKICAgINCX0L3QsNGH0LXQvdC40Y8gPSDQndC+0LLRi9C5INCh0L/QuNGB0L7QutCX0L3QsNGH0LXQvdC40Lk7CiAgICDQl9C90LDRh9C10L3QuNGPLtCU0L7QsdCw0LLQuNGC0YwoImh0dHA6Ly9sb2NhbGhvc3Q6ODA4MCIsICJVVE0gbG9jYWxob3N0OjgwODAiKTsKICAgINCX0L3QsNGH0LXQvdC40Y8u0JTQvtCx0LDQstC40YLRjCgiaHR0cDovLzEyNy4wLjAuMTo4MDgwIiwgIlVUTSAxMjcuMC4wLjE6ODA4MCIpOwogICAg0JfQvdCw0YfQtdC90LjRjy7QlNC+0LHQsNCy0LjRgtGMKCJodHRwOi8vMTAuMC4wLjEwMDo4MDg2IiwgIlVUTSAxMC4wLjAuMTAwOjgwODYiKTsKICAgINCS0YvQsdGA0LDQvdC90L7QtSA9INCX0L3QsNGH0LXQvdC40Y8u0JLRi9Cx0YDQsNGC0YzQrdC70LXQvNC10L3Rgigi0JLRi9Cx0LXRgNC40YLQtSDQo9Ci0JwiKTsKICAgINCV0YHQu9C4INCS0YvQsdGA0LDQvdC90L7QtSA9INCd0LXQvtC/0YDQtdC00LXQu9C10L3QviDQotC+0LPQtNCwINCS0L7Qt9Cy0YDQsNGCOyDQmtC+0L3QtdGG0JXRgdC70Lg7CiAgICDQkNC00YDQtdGB0KPQotCcID0g0JLRi9Cx0YDQsNC90L3QvtC1LtCX0L3QsNGH0LXQvdC40LU7CiAgICDQo9Ci0JzQlNC+0YHRgtGD0L/QtdC9ID0g0JvQvtC20Yw7CiAgICDQodGC0LDRgtGD0YHRi9Cf0L7Qu9GD0YfQtdC90YsgPSDQm9C+0LbRjDsKICAgINCg0LXQt9GD0LvRjNGC0LDRgiA9ICLQktGL0LHRgNCw0L0g0KPQotCcOiAiICsg0JDQtNGA0LXRgdCj0KLQnDsK0JrQvtC90LXRhtCf0YDQvtGG0LXQtNGD0YDRiwoKJtCd0LDQmtC70LjQtdC90YLQtQrQn9GA0L7RhtC10LTRg9GA0LAgQ2hlY2tVVE0o0JrQvtC80LDQvdC00LApCiAgICDQldGB0LvQuCDQn9GD0YHRgtCw0Y/QodGC0YDQvtC60LAo0JDQtNGA0LXRgdCj0KLQnCkg0KLQvtCz0LTQsAogICAgICAgINCg0LXQt9GD0LvRjNGC0LDRgiA9ICLQodC90LDRh9Cw0LvQsCDQstGL0LHQtdGA0LjRgtC1INCj0KLQnC4iOwogICAgICAgINCS0L7Qt9Cy0YDQsNGCOwogICAg0JrQvtC90LXRhtCV0YHQu9C4OwogICAg0J7RgtCy0LXRgiA9INCf0L7Qu9GD0YfQuNGC0YzQodGC0LDRgtGD0YHRi9Cj0KLQnNCd0LDQodC10YDQstC10YDQtSjQkNC00YDQtdGB0KPQotCcLCDQotCw0LnQvNCw0YPRgtCj0KLQnCk7CiAgICDQldGB0LvQuCDQntGC0LLQtdGCID0g0J3QtdC+0L/RgNC10LTQtdC70LXQvdC+INCi0L7Qs9C00LAKICAgICAgICDQo9Ci0JzQlNC+0YHRgtGD0L/QtdC9ID0g0JvQvtC20Yw7CiAgICAgICAg0KHRgtCw0YLRg9GB0YvQn9C+0LvRg9GH0LXQvdGLID0g0JvQvtC20Yw7CiAgICAgICAg0KDQtdC30YPQu9GM0YLQsNGCID0gItCj0KLQnCDQvdC1INCy0LXRgNC90YPQuyDRgNC10LfRg9C70YzRgtCw0YIuIjsKICAgICAgICDQktC+0LfQstGA0LDRgjsKICAgINCa0L7QvdC10YbQldGB0LvQuDsKICAgINCV0YHQu9C4INCd0LUg0J7RgtCy0LXRgi7Qo9GB0L/QtdGI0L3QviDQotC+0LPQtNCwCiAgICAgICAg0KPQotCc0JTQvtGB0YLRg9C/0LXQvSA9INCb0L7QttGMOwogICAgICAgINCh0YLQsNGC0YPRgdGL0J/QvtC70YPRh9C10L3RiyA9INCb0L7QttGMOwogICAgICAgINCg0LXQt9GD0LvRjNGC0LDRgiA9INCe0YLQstC10YIu0KHQvtC+0LHRidC10L3QuNC1OwogICAgICAgINCS0L7Qt9Cy0YDQsNGCOwogICAg0JrQvtC90LXRhtCV0YHQu9C4OwogICAg0KPQotCc0JTQvtGB0YLRg9C/0LXQvSA9INCY0YHRgtC40L3QsDsKICAgINCh0YLQsNGC0YPRgdGL0J/QvtC70YPRh9C10L3RiyA9INCY0YHRgtC40L3QsDsKICAgINCg0LXQt9GD0LvRjNGC0LDRgiA9ICLQo9Ci0Jwg0LTQvtGB0YLRg9C/0LXQvS4g0JTQvtC60YPQvNC10L3RgtC+0LI6ICIgKyDQodGC0YDQvtC60LAo0J7RgtCy0LXRgi7QotCi0J0u0JrQvtC70LjRh9C10YHRgtCy0L4oKSk7CtCa0L7QvdC10YbQn9GA0L7RhtC10LTRg9GA0YsKCibQndCw0JrQu9C40LXQvdGC0LUK0J/RgNC+0YbQtdC00YPRgNCwIFNlbGVjdFRUTijQmtC+0LzQsNC90LTQsCkKICAgINCV0YHQu9C4INCi0LDQsdC70LjRhtCw0KLQotCdLtCa0L7Qu9C40YfQtdGB0YLQstC+KCkgPSAwINCi0L7Qs9C00LAKICAgICAgICDQoNC10LfRg9C70YzRgtCw0YIgPSAi0KHQvdCw0YfQsNC70LAg0L/QvtC70YPRh9C40YLQtSDQtNCw0L3QvdGL0LUg0LjQtyDQo9Ci0JwuIjsKICAgICAgICDQktC+0LfQstGA0LDRgjsKICAgINCa0L7QvdC10YbQldGB0LvQuDsKICAgINCi0LXQutGD0YnQuNC10JTQsNC90L3Ri9C1ID0g0K3Qu9C10LzQtdC90YLRiy7QotCi0J0u0KLQtdC60YPRidC40LXQlNCw0L3QvdGL0LU7CiAgICDQldGB0LvQuCDQotC10LrRg9GJ0LjQtdCU0LDQvdC90YvQtSA9INCd0LXQvtC/0YDQtdC00LXQu9C10L3QviDQotC+0LPQtNCwCiAgICAgICAg0KDQtdC30YPQu9GM0YLQsNGCID0gItCS0YvQsdC10YDQuNGC0LUg0YHRgtGA0L7QutGDINCi0KLQnSDQsiDRgtCw0LHQu9C40YbQtS4iOwogICAgICAgINCS0L7Qt9Cy0YDQsNGCOwogICAg0JrQvtC90LXRhtCV0YHQu9C4OwogICAg0JLRi9Cx0YDQsNC90L3QsNGP0KLQotCdID0g0KLQtdC60YPRidC40LXQlNCw0L3QvdGL0LUu0J3QvtC80LXRgNCi0KLQnTsKICAgINCg0LXQt9GD0LvRjNGC0LDRgiA9ICLQktGL0LHRgNCw0L3QsCDQotCi0J06ICIgKyDQktGL0LHRgNCw0L3QvdCw0Y/QotCi0J07CtCa0L7QvdC10YbQn9GA0L7RhtC10LTRg9GA0YsK'
    $m = $m.Insert($pos, $insert + [Environment]::NewLine)
}

# Add selected TTN filter to the first two correction loops.
$loop = Decode '0JTQu9GPINC60LDQttC00L7Qs9C+INCh0YLRgNC+0LrQsNCi0KLQnSDQmNC3INCi0LDQsdC70LjRhtCw0KLQotCdINCm0LjQutC7Cg=='
$filter = Decode 'ICAgICAgICDQldGB0LvQuCDQndC1INCf0YPRgdGC0LDRj9Ch0YLRgNC+0LrQsCjQktGL0LHRgNCw0L3QvdCw0Y/QotCi0J0pINCYINCh0YLRgNC+0LrQsNCi0KLQnS7QndC+0LzQtdGA0KLQotCdIDw+INCS0YvQsdGA0LDQvdC90LDRj9Ci0KLQnSDQotC+0LPQtNCwINCf0YDQvtC00L7Qu9C20LjRgtGMOyDQmtC+0L3QtdGG0JXRgdC70Lg7Cg=='
if ($m -notmatch 'ПустаяСтрока\(ВыбраннаяТТН\)') {
    $m = $m.Replace($loop, $loop + $filter)
    $m = $m.Replace($loop, $loop + $filter)
}
Set-Content -LiteralPath $Module -Value $m -Encoding UTF8

$f = Get-Content -LiteralPath $Form -Raw -Encoding UTF8

if ($f -notmatch 'name="ВыбраннаяТТН"') {
    $attr = Decode 'ICAgIDxBdHRyaWJ1dGUgbmFtZT0i0JLRi9Cx0YDQsNC90L3QsNGP0KLQotCdIiBpZD0iOCI+PFRpdGxlPjx2ODppdGVtPjx2ODpsYW5nPnJ1PC92ODpsYW5nPjx2ODpjb250ZW50PlNlbGVjdGVkIFRUTjwvdjg6Y29udGVudD48L3Y4Oml0ZW0+PC9UaXRsZT48VHlwZT48djg6VHlwZT54czpzdHJpbmc8L3Y4OlR5cGU+PHY4OlN0cmluZ1F1YWxpZmllcnM+PHY4Okxlbmd0aD4xMDA8L3Y4Okxlbmd0aD48djg6QWxsb3dlZExlbmd0aD5WYXJpYWJsZTwvdjg6QWxsb3dlZExlbmd0aD48L3Y4OlN0cmluZ1F1YWxpZmllcnM+PC9UeXBlPjwvQXR0cmlidXRlPgo='
    $f = $f.Replace('  </Attributes>' + [Environment]::NewLine, $attr + '  </Attributes>' + [Environment]::NewLine)
}

if ($f -notmatch 'Command name="SelectUTM"') {
    $buttons = @'
      <Button name="SelectUTM" id="30"><Type>UsualButton</Type><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Select UTM</v8:content></v8:item></Title><CommandName>Form.Command.SelectUTM</CommandName></Button>
      <Button name="CheckUTM" id="31"><Type>UsualButton</Type><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Check UTM</v8:content></v8:item></Title><CommandName>Form.Command.CheckUTM</CommandName></Button>
      <Button name="SelectTTN" id="32"><Type>UsualButton</Type><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Select TTN</v8:content></v8:item></Title><CommandName>Form.Command.SelectTTN</CommandName></Button>
'@
    $f = [regex]::Replace($f, '(?m)^\s*<Button\b', $buttons + '      <Button', 1)
}

if ($f -notmatch 'Command name="SelectUTM"') {
    $commands = @'
    <Command name="SelectUTM" id="30"><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Select UTM</v8:content></v8:item></Title><Action>SelectUTM</Action><CurrentRowUse>DontUse</CurrentRowUse></Command>
    <Command name="CheckUTM" id="31"><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Check UTM</v8:content></v8:item></Title><Action>CheckUTM</Action><CurrentRowUse>DontUse</CurrentRowUse></Command>
    <Command name="SelectTTN" id="32"><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Select TTN</v8:content></v8:item></Title><Action>SelectTTN</Action><CurrentRowUse>DontUse</CurrentRowUse></Command>
'@
    $f = [regex]::Replace($f, '(?m)^\s*</Commands>', $commands + '  </Commands>', 1)
}
Set-Content -LiteralPath $Form -Value $f -Encoding UTF8
Write-Host 'PATCH OK: UTM 406 fix + UTM/TTN selection.' -ForegroundColor Green
