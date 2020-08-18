# OnlineChatSdk-Swift
[![Version](https://img.shields.io/cocoapods/v/OnlineChatSdk.svg?style=flat)](https://cocoapods.org/pods/OnlineChatSdk)
[![License](https://img.shields.io/cocoapods/l/OnlineChatSdk.svg?style=flat)](https://cocoapods.org/pods/OnlineChatSdk)
![Platform](https://img.shields.io/cocoapods/p/SwiftMessages.svg?style=flat)

![](https://github.com/bekannax/OnlineChatSdk-Swift/blob/master/images/2020-08-18_17-43-31.png?raw=true)

## Добавление в проект
```ruby
pod 'OnlineChatSdk'
```

## Получение id
Перейдите в раздел «Online чат - Ваш сайт - Настройки - Установка» и скопируйте значение переменной id.
![](https://github.com/bekannax/OnlineChatSdk-Android/blob/master/images/2019-03-21_16-53-28.png?raw=true)

## Пример использования
Добавьте свой `ViewController` с суперклассом `ChatController`. 
```swift
class MyController: ChatController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        load("<Ваш id>", "<Домен вашего сайта>")
    }
}
```
Так же при загрузке можно указать `language`, `clientId` и `apiToken`.
```swift
load("<Ваш id>", "<Домен вашего сайта>", "en", "newClientId", "<Токен для доступа к Rest Api>")
```

## События
 * **operatorSendMessage** - оператор отправил сообщение посетителю.
 * **clientSendMessage** - посетитель отправил сообщение оператору.
 * **clientMakeSubscribe** - посетитель заполнил форму.
 * **contactsUpdated** - посетитель обновил информацию о себе.
 * **sendRate** - посетитель отправил новый отзыв.
 * **clientId** - уникальный идентификатор посетителя.

Для каждого события есть персональный обработчик.
```swift
override func onOperatorSendMessage(_ data: NSDictionary) {

}

override func onClientSendMessage(_ data: NSDictionary) {

}

override func onClientMakeSubscribe(_ data: NSDictionary) {

}

override func onContactsUpdated(_ data: NSDictionary) {

}

override func onSendRate(_ data: NSDictionary) {

}

override func onClientId(_ clientId: String) {

}
```
Или можно задать один обработчик на все события.
```swift
override func onEvent(_ name: String, _ data: NSDictionary) {
     switch name {
         case ChatController.event_operatorSendMessage:
             break
         case ChatController.event_clientSendMessage:
             break
         case ChatController.event_clientMakeSubscribe:
             break
         case ChatController.event_contactsUpdated:
             break
         case ChatController.event_sendRate:
             break
         case ChatController.event_clientId:
             break
         case ChatController.method_getContacts:
             break
         default:
             break
     }
}
```

## Методы
 * **setClientInfo** - изменение информации о посетителе.
 * **setTarget** - пометить посетителя целевым.
 * **openReviewsTab** - отобразить форму для отзыва.
 * **openTab** - отобразить необходимую вкладку.
 * **sendMessage** - отправка сообщения от имени клиента.
 * **receiveMessage** - отправка сообщения от имени оператора.
 * **setOperator** - выбор любого оператора.
 * **getContacts** - получение контактных данных.

```swift
callJsSetClientInfo("{name: \"Имя\", email: \"test@mail.ru\"}")

callJsSetTarget("reason")

callJsOpenReviewsTab()

callJsOpenTab(1)

callJsSendMessage("Здравствуйте! У меня серьёзная проблема!")

callJsReceiveMessage("Мы уже спешим на помощь ;)", "", 2000)

callJsSetOperator("Логин оператора")

callJsGetContacts() // результат прилетает в getContactsCallback
override func getContactsCallback(_ data: NSDictionary) {
        
}
```
Подробное описание методов можно прочесть в разделе «Интеграция и API - Javascript API».

## Получение token
Перейдите в раздел «Интеграция и API - REST API», скопируйте существующий token или добавьте новый.

![](https://github.com/bekannax/OnlineChatSdk-Android/blob/master/images/2019-04-01_18-32-22.png?raw=true)

## Получение новых сообщений от оператора
Для получения новых сообщений, в `ChatController` есть два статичных метода `getUnreadedMessages` и `getNewMessages`.

**getUnreadedMessages** - возвращает все непрочитанные сообщения от оператора.

**getNewMessages** так же возвращает непрочитанные сообщения, но при следующих запросах предыдущие сообщения уже не возвращаются. 

Перед использование методов, нужно указать `apiToken`.

```swift
ChatController.getUnreadedMessages { data in }
ChatController.getNewMessages { data in }
```
Формат `data` аналогичен ответу метода /chat/message/getList в Rest Api.

Подробное описание можно прочесть в разделе «Интеграция и API - REST API - Инструкции по подключению».

![](https://github.com/bekannax/OnlineChatSdk-Android/blob/master/images/2020-08-14_19-05-48.png?raw=true)

## License

OnlineChatSdk is available under the MIT license. See the LICENSE file for more info.
