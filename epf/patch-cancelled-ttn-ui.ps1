$ErrorActionPreference = 'Stop'

$EpRoot = Join-Path $PSScriptRoot 'EgaisCancelledTTN2026'
$Module = Join-Path $EpRoot 'Forms\Форма\Ext\Form\Module.bsl'
$Form = Join-Path $EpRoot 'Forms\Форма\Ext\Form.xml'

if (!(Test-Path -LiteralPath $Module)) { throw "Module not found: $Module" }
if (!(Test-Path -LiteralPath $Form)) { throw "Form XML not found: $Form" }

$m = Get-Content -LiteralPath $Module -Raw -Encoding UTF8
$m = $m.Replace('            Запрос.Заголовки.Вставить("Accept", "application/xml");' + [Environment]::NewLine, '')

if ($m -notmatch 'Процедура ВыбратьУТМ') {
$insert = @'

&НаКлиенте
Процедура ВыбратьУТМ(Команда)
    Значения = Новый СписокЗначений;
    Значения.Добавить("http://localhost:8080", "Локальный УТМ: localhost:8080");
    Значения.Добавить("http://127.0.0.1:8080", "Локальный УТМ: 127.0.0.1:8080");
    Значения.Добавить("http://10.0.0.100:8086", "Удалённый УТМ: 10.0.0.100:8086");
    Если Не ПустаяСтрока(АдресУТМ) Тогда
        Значения.Добавить(АдресУТМ, "Текущий адрес: " + АдресУТМ);
    КонецЕсли;
    Выбранное = Значения.ВыбратьЭлемент("Выберите УТМ");
    Если Выбранное = Неопределено Тогда Возврат; КонецЕсли;
    АдресУТМ = Выбранное.Значение;
    УТМДоступен = Ложь;
    СтатусыПолучены = Ложь;
    Результат = "Выбран УТМ: " + АдресУТМ + ". Нажмите «Проверить УТМ» или «Получить данные из УТМ».";
КонецПроцедуры

&НаКлиенте
Процедура ПроверитьУТМ(Команда)
    Если ПустаяСтрока(АдресУТМ) Тогда
        Результат = "Сначала выберите или укажите адрес УТМ.";
        Возврат;
    КонецЕсли;
    Ответ = ПолучитьСтатусыУТМНаСервере(АдресУТМ, ТаймаутУТМ);
    Если Ответ = Неопределено ИЛИ Не Ответ.Успешно Тогда
        УТМДоступен = Ложь;
        СтатусыПолучены = Ложь;
        Результат = ?(Ответ = Неопределено, "УТМ не вернул результат.", Ответ.Сообщение);
        Возврат;
    КонецЕсли;
    УТМДоступен = Истина;
    Результат = "УТМ доступен. HTTP-запрос выполнен успешно. Документов в ответе: " + Строка(Ответ.ТТН.Количество()) + ".";
КонецПроцедуры

&НаКлиенте
Процедура ВыбратьТТН(Команда)
    Если ТаблицаТТН.Количество() = 0 Тогда
        Результат = "Список ТТН пуст. Сначала нажмите «Получить данные из УТМ».";
        Возврат;
    КонецЕсли;
    ТекущиеДанные = Элементы.ТТН.ТекущиеДанные;
    Если ТекущиеДанные = Неопределено Тогда
        Результат = "Выберите строку ТТН в таблице.";
        Возврат;
    КонецЕсли;
    ВыбраннаяТТН = ТекущиеДанные.НомерТТН;
    Результат = "Выбрана ТТН: " + ВыбраннаяТТН + ". Теперь действие исправления будет выполнено только для неё.";
КонецПроцедуры
'@
    $marker = '&НаКлиенте' + [Environment]::NewLine + 'Процедура ПолучитьДанныеИзУТМ'
    $m = $m.Replace($marker, $insert + [Environment]::NewLine + $marker)
}

$m = $m.Replace('    Для каждого СтрокаТТН Из ТаблицаТТН Цикл' + [Environment]::NewLine + '        Если Не СтрокаТТН.Расхождение ИЛИ Не СтрокаТТН.ОтмененаПоставщиком Тогда', '    Для каждого СтрокаТТН Из ТаблицаТТН Цикл' + [Environment]::NewLine + '        Если Не ПустаяСтрока(ВыбраннаяТТН) И СтрокаТТН.НомерТТН <> ВыбраннаяТТН Тогда Продолжить; КонецЕсли;' + [Environment]::NewLine + '        Если Не СтрокаТТН.Расхождение ИЛИ Не СтрокаТТН.ОтмененаПоставщиком Тогда')
$m = $m.Replace('    Для каждого СтрокаТТН Из ТаблицаТТН Цикл' + [Environment]::NewLine + '        Если Не СтрокаТТН.Расхождение ИЛИ Не СтрокаТТН.ОтмененаПоставщиком Тогда Продолжить; КонецЕсли;', '    Для каждого СтрокаТТН Из ТаблицаТТН Цикл' + [Environment]::NewLine + '        Если Не ПустаяСтрока(ВыбраннаяТТН) И СтрокаТТН.НомерТТН <> ВыбраннаяТТН Тогда Продолжить; КонецЕсли;' + [Environment]::NewLine + '        Если Не СтрокаТТН.Расхождение ИЛИ Не СтрокаТТН.ОтмененаПоставщиком Тогда Продолжить; КонецЕсли;')
Set-Content -LiteralPath $Module -Value $m -Encoding UTF8

$f = Get-Content -LiteralPath $Form -Raw -Encoding UTF8
if ($f -notmatch 'name="ВыбраннаяТТН"') {
    $attr = '    <Attribute name="ВыбраннаяТТН" id="8"><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Выбранная ТТН</v8:content></v8:item></Title><Type><v8:Type>xs:string</v8:Type><v8:StringQualifiers><v8:Length>100</v8:Length><v8:AllowedLength>Variable</v8:AllowedLength></v8:StringQualifiers></Type></Attribute>'
    $f = $f.Replace('  </Attributes>' + [Environment]::NewLine, $attr + [Environment]::NewLine + '  </Attributes>' + [Environment]::NewLine)
}
if ($f -notmatch 'Command name="ВыбратьУТМ"') {
    $buttons = '      <Button name="ВыбратьУТМ" id="30"><Type>UsualButton</Type><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Выбрать УТМ</v8:content></v8:item></Title><CommandName>Form.Command.ВыбратьУТМ</CommandName></Button>' + [Environment]::NewLine +
               '      <Button name="ПроверитьУТМ" id="31"><Type>UsualButton</Type><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Проверить УТМ</v8:content></v8:item></Title><CommandName>Form.Command.ПроверитьУТМ</CommandName></Button>' + [Environment]::NewLine +
               '      <Button name="ВыбратьТТН" id="32"><Type>UsualButton</Type><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Выбрать ТТН</v8:content></v8:item></Title><CommandName>Form.Command.ВыбратьТТН</CommandName></Button>' + [Environment]::NewLine
    $needle = '      <Button name="Получить" id="5">'
    $f = $f.Replace($needle, $buttons + $needle)
}
if ($f -notmatch 'Command name="ВыбратьУТМ"') {
    $commands = '    <Command name="ВыбратьУТМ" id="30"><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Выбрать УТМ</v8:content></v8:item></Title><Action>ВыбратьУТМ</Action><CurrentRowUse>DontUse</CurrentRowUse></Command>' + [Environment]::NewLine +
                '    <Command name="ПроверитьУТМ" id="31"><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Проверить УТМ</v8:content></v8:item></Title><Action>ПроверитьУТМ</Action><CurrentRowUse>DontUse</CurrentRowUse></Command>' + [Environment]::NewLine +
                '    <Command name="ВыбратьТТН" id="32"><Title><v8:item><v8:lang>ru</v8:lang><v8:content>Выбрать ТТН</v8:content></v8:item></Title><Action>ВыбратьТТН</Action><CurrentRowUse>DontUse</CurrentRowUse></Command>' + [Environment]::NewLine
    $f = $f.Replace('  </Commands>' + [Environment]::NewLine, $commands + '  </Commands>' + [Environment]::NewLine)
}
Set-Content -LiteralPath $Form -Value $f -Encoding UTF8
Write-Host 'PATCH OK: UTM 406 fix + UTM/TTN buttons + selected TTN mode.' -ForegroundColor Green
