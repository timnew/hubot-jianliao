{TextMessage, User} = require 'hubot'
WebHookAdapter = require('./WebHookAdapter')

class JianLiaoAdapter extends WebHookAdapter
  parseChatMessage: (incomingMessage) ->
    text = incomingMessage.body
    messageId = incomingMessage._id

    new TextMessage(@extractUser(incomingMessage), text, messageId)

  extractUser: (incomingMessage) ->
    rawUser = incomingMessage.creator

    userInfo =
      id: rawUser._id
      name: rawUser.name

    if incomingMessage.room?
      rawRoom = incomingMessage.room
      userInfo.room =
        id: rawRoom._id
        topic: rawRoom.topic

    new User(userInfo.id, userInfo)

  buildChatMessage: (envelope, text) ->
    message =
     content: text

    if envelope.room?
      message._roomId = envelope.room.id
    else
      message._toId = envelope.user.id

    message

exports.use = (robot) ->
  new JianLiaoAdapter robot
