/**
 * Created by dowin on 2017/8/2.
 */
import { NativeModules,Platform } from 'react-native'
const { AvChatSession } = NativeModules;
class AvChat {
    callAvChat = ({sessionId, sessionName, chatType}) => {
        AvChatSession.callAvChat({sessionId, sessionName, chatType})
    }
}
export default new AvChat()
