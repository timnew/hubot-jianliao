# Hubot dependencies
{Robot, Adapter, TextMessage, Response, User} = require 'hubot'
url = require('url')

###
Overrides parseChatMessage(body, req, res)
Overrides buildChatMessage({user, room, message}, text)
###
class WebHookAdapter extends Adapter
  run: ->
    @configOutgoingWebHook()
    @configIncommingWebHook()

    @robot.logger.info "#{@robot.name} is online."

    @emit 'connected'

  logAndThrow: (message) ->
    @robot.logger.error(message)
    throw new Error(message)

  parseWebHookUrl: (pathOrUrl, defaultValue = '') ->
    parsedUrl = url.parse(pathOrUrl || defaultValue)

    if parsedUrl.protocol? and parsedUrl.protocol != 'https:'
      @robot.logger.warn('To ensure privacy and data security, web hook should be https')

    return parsedUrl

  configOutgoingWebHook: ->
    parsedUrl = @parseWebHookUrl(process.env.HUBOT_CHAT_OUTGOING_WEBHOOK, '/webhook/outgoing')

    unless parsedUrl.path?
      @logAndThrow('HUBOT_CHAT_OUTGOING_WEBHOOK must be set for hubot to recieve message from chat app')

    if parsedUrl.protocol? or parsedUrl.host? or parsedUrl.search?
      @robot.logger.warn('Chat Out Going Webhook should be a relative path')

    @outgoingWebHook = parsedUrl.pathname

    @robot.router.post @outgoingWebHook, @chatOutgoingMessageHandler

    @robot.logger.info('Register Chat Outgoing Webhook at %s', @outgoingWebHook)

  chatOutgoingMessageHandler: (req, res) =>
    @robot.logger.debug req.body

    try
      message = @parseChatMessage(req.body, req, res)
    catch ex
      @robot.logger.error('Crashed when parsing chat message', ex)
      return

    @robot.logger.info 'Recieved message: ', message
    @respondChatMessageRequest(res, message, req)

    @receive message

  parseChatMessage: (body) ->
    throw new Error('Derived class must return Messsage instance')

  respondChatMessageRequest: (res) ->
    res.status(200).end()

  configIncommingWebHook: ->
    parsedUrl = @parseWebHookUrl(process.env.HUBOT_CHAT_INCOMING_WEBHOOK)

    unless parsedUrl.path?
      @logAndThrow('HUBOT_CHAT_INCOMING_WEBHOOK must be set for hubot to send message to chat app')

    unless parsedUrl.protocol? and parsedUrl.host?
      @logAndThrow('HUBOT_CHAT_INCOMING_WEBHOOK must be a absolute url to the chat app')

    @incomingWebHook = parsedUrl.href

    @robot.logger.info('Register Chat Incomming Webhook at %s', @incomingWebHook)

  buildChatMessage: (envelope, text) ->
    throw new Error('Derived class must return body for chat app')

  send: (envelope, strings...) ->
    @robot.logger.info 'Send message', strings...

    text = strings.join('\\n')
    @robot.logger.debug('joined response: ', text)

    @robot.logger.debug('envelope: ', envelope)

    jsonObj = @buildChatMessage(envelope, text)
    @robot.logger.debug("Output Body: ", jsonObj)

    json = JSON.stringify jsonObj

    @robot.http(@incomingWebHook)
          .header('Content-Type', 'application/json')
          .post(json) (err, res, body) =>
            @robot.logger.info 'message sent', body

  reply: (envelope, strings...) ->
    @send envelope, strings...

module.exports = WebHookAdapter
