import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1280
    height: 800
    color: "#2E3440"

    readonly property color cBg: "#2E3440"
    readonly property color cSurface: "#3B4252"
    readonly property color cSurface2: "#434C5E"
    readonly property color cText: "#D8DEE9"
    readonly property color cMuted: "#81A1C1"
    readonly property color cAccent: "#88C0D0"
    readonly property color cUrgent: "#BF616A"

    property int sessionIndex: sessionModel.lastIndex

    LayoutMirroring.enabled: Qt.locale().textDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    TextConstants { id: textConstants }

    Connections {
        target: sddm
        function onLoginSucceeded() {
            statusText.color = cAccent
            statusText.text = textConstants.loginSucceeded
        }
        function onLoginFailed() {
            password.text = ""
            statusText.color = cUrgent
            statusText.text = textConstants.loginFailed
        }
        function onInformationMessage(message) {
            statusText.color = cUrgent
            statusText.text = message
        }
    }

    Background {
        id: wallpaper
        anchors.fill: parent
        source: Qt.resolvedUrl(config.background)
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        anchors.fill: parent
        color: cBg
        opacity: 0.5
    }

    // Clock, top-right
    Column {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 28
        spacing: 2

        Text {
            id: clockTime
            anchors.right: parent.right
            color: cText
            font.family: "JetBrains Mono"
            font.pixelSize: 34
            font.weight: Font.Medium
            text: Qt.formatTime(new Date(), "hh:mm")
        }
        Text {
            anchors.right: parent.right
            color: cMuted
            font.family: "JetBrains Mono"
            font.pixelSize: 13
            text: Qt.formatDate(new Date(), "dddd, d MMMM")
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            clockTime.text = Qt.formatTime(new Date(), "hh:mm")
        }
    }

    // Login card
    Rectangle {
        id: card
        width: 340
        anchors.centerIn: parent
        radius: 18
        color: Qt.rgba(0.231, 0.259, 0.322, 0.92) // cSurface @ 92%
        border.color: cSurface2
        border.width: 1
        height: cardColumn.implicitHeight + 56

        opacity: 0
        Component.onCompleted: cardOpacity.start()
        NumberAnimation {
            id: cardOpacity
            target: card
            property: "opacity"
            from: 0; to: 1
            duration: 260
            easing.type: Easing.OutCubic
        }

        Column {
            id: cardColumn
            anchors.centerIn: parent
            width: parent.width - 56
            spacing: 16

            Text {
                width: parent.width
                text: textConstants.welcomeText.arg(sddm.hostName)
                color: cAccent
                font.family: "JetBrains Mono"
                font.pixelSize: 17
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            // Username field
            Rectangle {
                width: parent.width
                height: 40
                radius: 10
                color: cSurface2
                border.width: 1
                border.color: name.activeFocus ? cAccent : "transparent"
                Behavior on border.color { ColorAnimation { duration: 150 } }

                TextInput {
                    id: name
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    color: cText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    text: userModel.lastUser
                    clip: true

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: textConstants.userName
                        color: cMuted
                        font: name.font
                        visible: name.text.length === 0
                    }

                    KeyNavigation.backtab: rebootButton
                    KeyNavigation.tab: password

                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            sddm.login(name.text, password.text, sessionIndex)
                            event.accepted = true
                        }
                    }
                }
            }

            // Password field
            Rectangle {
                width: parent.width
                height: 40
                radius: 10
                color: cSurface2
                border.width: 1
                border.color: password.activeFocus ? cAccent : "transparent"
                Behavior on border.color { ColorAnimation { duration: 150 } }

                TextInput {
                    id: password
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    color: cText
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    echoMode: TextInput.Password
                    clip: true

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: textConstants.password
                        color: cMuted
                        font: password.font
                        visible: password.text.length === 0
                    }

                    KeyNavigation.backtab: name
                    KeyNavigation.tab: session

                    Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            sddm.login(name.text, password.text, sessionIndex)
                            event.accepted = true
                        }
                    }
                }
            }

            Text {
                id: statusText
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: cMuted
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                height: 14
                text: ""
            }

            ComboBox {
                id: session
                width: parent.width
                height: 32
                visible: sessionModel.count > 1
                font.family: "JetBrains Mono"
                font.pixelSize: 12

                color: cSurface2
                borderColor: "transparent"
                focusColor: cAccent
                hoverColor: cSurface
                menuColor: cSurface2
                textColor: cText

                arrowIcon: Qt.resolvedUrl("angle-down.png")
                model: sessionModel
                index: sessionModel.lastIndex
                onValueChanged: sessionIndex = index

                KeyNavigation.backtab: password
                KeyNavigation.tab: loginButton
            }

            // Login button
            Rectangle {
                id: loginButton
                width: parent.width
                height: 40
                radius: 10
                color: loginArea.containsMouse ? Qt.lighter(cAccent, 1.08) : cAccent
                Behavior on color { ColorAnimation { duration: 120 } }

                activeFocusOnTab: true
                KeyNavigation.backtab: session
                KeyNavigation.tab: shutdownButton

                Text {
                    anchors.centerIn: parent
                    text: textConstants.login
                    color: cBg
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: loginArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.login(name.text, password.text, sessionIndex)
                }

                Keys.onPressed: function (event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        sddm.login(name.text, password.text, sessionIndex)
                        event.accepted = true
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                Text {
                    id: shutdownButton
                    text: textConstants.shutdown
                    color: shutdownArea.containsMouse ? cText : cMuted
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    Behavior on color { ColorAnimation { duration: 120 } }

                    KeyNavigation.backtab: loginButton
                    KeyNavigation.tab: rebootButton

                    MouseArea {
                        id: shutdownArea
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sddm.powerOff()
                    }
                }

                Text {
                    id: rebootButton
                    text: textConstants.reboot
                    color: rebootArea.containsMouse ? cText : cMuted
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    Behavior on color { ColorAnimation { duration: 120 } }

                    KeyNavigation.backtab: shutdownButton
                    KeyNavigation.tab: name

                    MouseArea {
                        id: rebootArea
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sddm.reboot()
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (name.text.length === 0)
            name.forceActiveFocus()
        else
            password.forceActiveFocus()
    }
}
