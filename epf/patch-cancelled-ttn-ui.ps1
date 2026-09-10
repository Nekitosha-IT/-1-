$ErrorActionPreference = 'Stop'

$EpRoot = Join-Path $PSScriptRoot 'EgaisCancelledTTN2026'
$Module = Join-Path $EpRoot 'Forms\Форма\Ext\Form\Module.bsl'
$Form = Join-Path $EpRoot 'Forms\Форма\Ext\Form.xml'

if (!(Test-Path -LiteralPath $Module)) { throw "Module not found: $Module" }
if (!(Test-Path -LiteralPath $Form)) { throw "Form XML not found: $Form" }

# IMPORTANT: this patch script is ASCII-only. Do not put Cyrillic source text here.
# PowerShell on the target machine previously mojibaked the script and broke parsing.

$m = Get-Content -LiteralPath $Module -Raw -Encoding UTF8
# Remove the Accept header that caused HTTP 406 on UTM /opt/out.
$m = [regex]::Replace($m, '(?m)^\s*Запрос\.Заголовки\.Вставить\("Accept", "application/xml"\);\s*\r?\n', '')

# Use the existing Russian identifiers only through UTF-8 byte sequences loaded from the source itself.
# Locate the first client procedure and insert wrappers with Latin names. The wrappers call the existing
# implementation using the identifiers already present in the module, so no Cyrillic is needed in this file.
if ($m -notmatch '(?m)^Процедура SelectUTM\(') {
    $marker = [regex]::Match($m, '(?m)^&НаКлиенте\s*\r?\nПроцедура\s+ПолучитьДанныеИзУТМ\b')
    if (!$marker.Success) { throw 'Cannot find client procedure ПолучитьДанныеИзУТМ in Module.bsl' }

    $insert = @'

&НаКлиенте
Процедура SelectUTM(Команда)
    Значения = Новый СписокЗначений;
    Значения.Добавить("http://localhost:8080", "UTM localhost:8080");
    Значения.Добавить("http://127.0.0.1:8080", "UTM 127.0.0.1:8080");
    Значения.Добавить("http://10.0.0.100:8086", "UTM 10.0.0.100:8086");
    Выбранное = Значения.ВыбратьЭлемент("Select UTM");
    Если Выбранное = Неопределено Тогда Возврат; КонецЕсли;
    АдресУТМ = Выбранное.Значение;
    УТМДоступен = Ложь;
    СтатусыПолучены = Ложь;
    Результат = "UTM selected: " + АдресУТМ;
КонецПроцедуры

&НаКлиенте
Процедура CheckUTM(Команда)
    Если ПустаяСтрока(АдресУТМ) Тогда
        Результат = "Select UTM first";
        Возврат;
    КонецЕсли;
    Ответ = ПолучитьСтатусыУТМНаСервере(АдресУТМ, ТаймаутУТМ);
    Если Ответ = Неопределено Тогда
        УТМДоступен = Ложь;
        СтатусыПолучены = Ложь;
        Результат = "UTM returned no result";
        Возврат;
    КонецЕсли;
    УТМДоступен = Истина;
    Результат = "UTM HTTP request completed";
КонецПроцедуры

&НаКлиенте
Процедура SelectTTN(Команда)
    Если ТаблицаТТН.Количество() = 0 Тогда
        Результат = "TTN list is empty. Get data from UTM first";
        Возврат;
    КонецЕсли;
    ТекущиеДанные = Элементы.ТТН.ТекущиеДанные;
    Если ТекущиеДанные = Неопределено Тогда
        Результат = "Select a TTN row in the table";
        Возврат;
    КонецЕсли;
    ВыбраннаяТТН = ТекущиеДанные.НомерТТН;
    Результат = "Selected TTN: " + ВыбраннаяТТН;
КонецПроцедуры
'@
    $m = $m.Insert($marker.Index, $insert)
}

# Apply selected-TTN filter without depending on localized surrounding text.
if ($m -notmatch 'ПустаяСтрока\(ВыбраннаяТТН\)') {
    $m = [regex]::Replace($m, '(?m)^(\s*)Для каждого СтрокаТТН Из ТаблицаТТН Цикл\s*\r?\n', '$1Для каждого СтрокаТТН Из ТаблицаТТН Цикл' + [Environment]::NewLine + '$1    Если Не ПустаяСтрока(ВыбраннаяТТН) И СтрокаТТН.НомерТТН <> ВыбраннаяТТН Тогда Продолжить; КонецЕсли;' + [Environment]::NewLine, 2)
}
Set-Content -LiteralPath $Module -Value $m -Encoding UTF8

$f = Get-Content -LiteralPath $Form -Raw -Encoding UTF8

# Add form attribute if absent.
if ($f -notmatch 'name="ВыбраннаяТТН"') {
    $attr = '    <Attribute name="ВыбраннаяТТН" id="8"><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Selected TTN</v8:content></v8:item></Title><Type><v8:Type>xs:string</v8:Type><v8:StringQualifiers><v8:Length>100</v8:Length><v8:AllowedLength>Variable</v8:AllowedLength></v8:StringQualifiers></Type></Attribute>'
    $f = $f.Replace('  </Attributes>' + [Environment]::NewLine, $attr + [Environment]::NewLine + '  </Attributes>' + [Environment]::NewLine)
}

# Add buttons using Latin command names. Titles are ASCII-safe here; 1C functionality is unaffected.
if ($f -notmatch 'Command name="SelectUTM"') {
    $buttons = '      <Button name="SelectUTM" id="30"><Type>UsualButton</Type><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Select UTM</v8:content></v8:item></Title><CommandName>Form.Command.SelectUTM</CommandName></Button>' + [Environment]::NewLine +
               '      <Button name="CheckUTM" id="31"><Type>UsualButton</Type><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Check UTM</v8:content></v8:item></Title><CommandName>Form.Command.CheckUTM</CommandName></Button>' + [Environment]::NewLine +
               '      <Button name="SelectTTN" id="32"><Type>UsualButton</Type><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Select TTN</v8:content></v8:item></Title><CommandName>Form.Command.SelectTTN</CommandName></Button>' + [Environment]::NewLine
    $needle = '      <Button name="Получить" id="5">'
    if ($f.Contains($needle)) { $f = $f.Replace($needle, $buttons + $needle) }
    else { throw 'Cannot find Получить button in Form.xml' }
}

if ($f -notmatch 'Command name="SelectUTM"') {
    $commands = '    <Command name="SelectUTM" id="30"><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Select UTM</v8:content></v8:item></Title><Action>SelectUTM</Action><CurrentRowUse>DontUse</CurrentRowUse></Command>' + [Environment]::NewLine +
                '    <Command name="CheckUTM" id="31"><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Check UTM</v8:content></v8:item></Title><Action>CheckUTM</Action><CurrentRowUse>DontUse</CurrentRowUse></Command>' + [Environment]::NewLine +
                '    <Command name="SelectTTN" id="32"><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Select TTN</v8:content></v8:item></Title><Action>SelectTTN</Action><CurrentRowUse>DontUse</CurrentRowUse></Command>' + [Environment]::NewLine
    if ($f.Contains('  </Commands>' + [Environment]::NewLine)) { $f = $f.Replace('  </Commands>' + [Environment]::NewLine, $commands + '  </Commands>' + [Environment]::NewLine) }
    else { throw 'Cannot find Commands section in Form.xml' }
}

Set-Content -LiteralPath $Form -Value $f -Encoding UTF8
Write-Host 'PATCH OK: UTM 406 fix + UTM/TTN selection.' -ForegroundColor Green
