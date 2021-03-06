package org.ensime.protocol

import java.io._
import org.ensime.config.{ProjectConfig, DebugConfig, ReplConfig}
import org.ensime.debug.{ DebugUnit, DebugSourceLinePairs }
import org.ensime.model._
import org.ensime.server._
import org.ensime.util._
import scala.actors._

case class IncomingMessageEvent(obj: Any)
case class OutgoingMessageEvent(obj: Any)

object ProtocolConst {

  val MsgCompilerUnexpectedError = 101
  val MsgInitializingAnalyzer = 102

  val MsgBuildingEntireProject = 103
  val MsgBuildComplete = 104

  val ErrExceptionInRPC = 201
  val ErrMalformedRPC = 202
  val ErrUnrecognizedForm = 203
  val ErrUnrecognizedRPC = 204
  val ErrExceptionInBuilder = 205

  val ErrPeekUndoFailed = 206
  val ErrExecUndoFailed = 207

  val ErrFormatFailed = 208

  val ErrAnalyzerNotReady = 209
  val ErrExceptionInAnalyzer = 210

}

trait Protocol[MsgType] extends ProtocolConversions[MsgType] {

  /**
   * Read a message from the socket.
   *
   * @param  reader  The reader from which to read the message.
   * @return         The message, in the intermediate format.
   */
  def readMessage(reader: Reader): MsgType

  /**
   * Write a message to the socket.
   *
   * @param  value  The message to write.
   * @param  writer The writer to which to write the message.
   * @return        Void
   */
  def writeMessage(value: MsgType, writer: Writer)

  /**
   * Send a message in wire format to the client. Message
   * will be sent to the outputPeer, and then written to the
   * output socket.
   *
   * @param  o  The message to send.
   * @return    Void
   */
  def sendMessage(o: MsgType) {
    peer ! OutgoingMessageEvent(o)
  }

  /**
   * Handle a message from the client. Generally
   * messages encode RPC calls, and will be delegated
   * to the rpcTarget.
   *
   * @param  msg  The message we've received.
   * @return        Void
   */
  def handleIncomingMessage(msg: MsgType)

  // this type unsafe helper function is used in Project Actor loop only
  def handleIncomingMessageAny(msg: Any){
    msg match {
      case m:MsgType => handleIncomingMessage(m)
      case _ => throw new Exception("failure") // should never be reached
    }
  }

  /**
   * Send a string to the client editor, to be displayed 
   * to the user. This is to be used for non-critical messaging
   * that the user may choose to ignore.
   *
   * @param  code  The code of the message to write.
   * @param  detail   Additional details if required.
   * @return        Void
   */
  def sendBackgroundMessage(code: Int, detail: Option[String])

  /**
   * Designate an actor that should receive outgoing 
   * messages. 
   * TODO: Perhaps a channel would be more efficient?
   *
   * @param  peer  The Actor.
   * @return        Void
   */
  def setOutputActor(peer: Actor)
  protected def peer: Actor

  /**
   * Designate the target to which RPC handling
   * should be delegated.
   *
   * @param  target The RPCTarget instance.
   * @return        Void
   */
  def setRPCTarget(target: RPCTarget)

  /**
   * Send a simple RPC Return with a 'true' value.
   * Serves to acknowledge the RPC call when no 
   * other return value is required.
   *
   * @param  callId The id of the RPC call.
   * @return        Void
   */
  def sendRPCAckOK(callId: Int)

  /**
   * Send an RPC Return with the given value.
   *
   * @param  value  The value to return.
   * @param  callId The id of the RPC call.
   * @return        Void
   */
  def sendRPCReturn(value: RPCResult, callId: Int)

  /**
   * Notify the client that the RPC call could not
   * be handled.
   *
   * @param  code  Integer code denoting error type.
   * @param  detail  A message describing the error.
   * @param  callId The id of the failed RPC call.
   * @return        Void
   */
  def sendRPCError(code: Int, detail: Option[String], callId: Int)

  /**
   * Notify the client that a message was received
   * that does not conform to the protocol.
   *
   * @param  code  Integer code denoting error type.
   * @param  detail  A message describing the problem.
   * @return        Void
   */
  def sendProtocolError(code: Int, detail: Option[String])

  /**
   * Send a structure describing the connection, protocol and
   * server. Probably not necessessary in all clients.
   *
   * @param  callId The id of the failed RPC call.
   * @return        Void
   */
  def sendConnectionInfo(callId: Int)

  /**
   * Send a notification that the interactive compiler is ready
   * to process queries. Editor should not allow commands until
   * this notification has been received.
   *
   * @return        Void
   */
  def sendCompilerReady()

  /**
   * Send notes describing errors, warnings that the compiler
   * generates. These results are generated asynchronously,
   * and not in response to any single RPC call.
   *
   * @param notes  The notes
   * @return        Void
   */
  def sendTypeCheckResult(notes: NoteList)

  def createSocketHandler(socket: java.net.Socket, project: Project) = {
     new SocketHandler(socket, this, project)
  }

}

trait ProtocolConversions[MsgType] {
  def toWF(config: ProjectConfig): MsgType
  def toWF(config: ReplConfig): MsgType
  def toWF(config: DebugConfig): MsgType
  def toWF(unit: DebugUnit): MsgType
  def toWF(value: Boolean): MsgType
  def toWF(value: DebugSourceLinePairs): MsgType
  def toWF(value: Note): MsgType
  def toWF(notelist: NoteList): MsgType;
  def toWF(values: Iterable[MsgType]): MsgType
  def toWF(value: SymbolInfoLight): MsgType
  def toWF(value: PackageMemberInfoLight): MsgType
  def toWF(value: SymbolInfo): MsgType
  def toWF(value: NamedTypeMemberInfoLight): MsgType
  def toWF(value: NamedTypeMemberInfo): MsgType
  def toWF(value: EntityInfo): MsgType
  def toWF(value: TypeInfo): MsgType
  def toWF(value: PackageInfo): MsgType
  def toWF(value: CallCompletionInfo): MsgType
  def toWF(value: InterfaceInfo): MsgType
  def toWF(value: TypeInspectInfo): MsgType
  def toWF(value: ImportSuggestions): MsgType

  def toWF(value: RefactorFailure): MsgType
  def toWF(value: RefactorEffect): MsgType
  def toWF(value: RefactorResult): MsgType
  def toWF(value: Undo): MsgType
  def toWF(value: UndoResult): MsgType
  def toWF(value: Null): MsgType

}
