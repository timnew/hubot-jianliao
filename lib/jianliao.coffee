{TextMessage, User} = require 'hubot'
WebHookAdapter = require('./WebHookAdapter')

class JianLiaoAdapter extends WebHookAdapter
  handleChatMessage: (incomingMessage) ->
    text = incomingMessage.content
    messageId = incomingMessage._id

    new TextMessage(@extractUser(incomingMessage), text, messageId)

  extractUser: (incomingMessage) ->
    rawUser = incomingMessage.creator
    rawRoom = incomingMessage.room

    userInfo =
      id: rawUser._id
      name: rawUser.name
      room:
        id: rawRoom._id
        topic: rawRoom.topic

    new User(userInfo.id, userInfo)

  buildChatMessage: (user, text) ->
    message =
     content: text

    if user.room?
      message._roomId = user.room.id
    else
      message._toId = user.id

    message

exports.use = (robot) ->
  new JianLiaoAdapter robot
