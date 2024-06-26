/****************************************************************************
**
** Copyright (C) VCreate Logic Pvt. Ltd. Bengaluru
** Author: Prashanth N Udupa (prashanth@scrite.io)
**
** This code is distributed under GPL v3. Complete text of the license
** can be found here: https://www.gnu.org/licenses/gpl-3.0.txt
**
** This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
** WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
**
****************************************************************************/

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import io.scrite.components 1.0

import "qrc:/js/utils.js" as Utils
import "qrc:/qml/globals"
import "qrc:/qml/controls"
import "qrc:/qml/helpers"
import "qrc:/qml/dialogs"
import "qrc:/qml/notifications"

VclMenu {
    id: structureGroupsMenu

    property SceneGroup sceneGroup: null
    signal toggled(int row, string name)
    closePolicy: Popup.CloseOnEscape|Popup.CloseOnPressOutside
    enabled: !Scrite.document.readOnly

    title: "Tag Groups"
    property string innerTitle: ""

    width: 450
    height: 500

    HelpTipNotification {
        id: htn
        tipName: "story_beat_tagging"
        enabled: false
    }
    onOpened: htn.enabled = true

    VclMenuItem {
        width: structureGroupsMenu.width
        height: structureGroupsMenu.height

        background: Item { }
        contentItem: Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.bottomMargin: structureGroupsMenu.bottomPadding
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    border.width: 1
                    border.color: Runtime.colors.primary.borderColor
                    enabled: Runtime.appFeatures.structure.enabled && sceneGroup.sceneCount > 0
                    opacity: enabled ? 1 : 0.5

                    Rectangle {
                        anchors.fill: innerTitleText
                        color: Runtime.colors.primary.c700.background
                        visible: innerTitleText.visible
                    }

                    VclLabel {
                        id: innerTitleText
                        width: parent.width - 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.margins: 3
                        wrapMode: Text.WordWrap
                        text: {
                            var ret = innerTitle
                            if(sceneGroup.hasSceneStackIds) {
                                if(ret !== "")
                                    ret += "<br/>"
                                ret += "<font size=\"-2\"><i>All scenes in the selected stack(s) are going to be tagged.</i></font>"
                            }
                            return ret;
                        }
                        font.pointSize: Runtime.idealFontMetrics.font.pointSize
                        visible: text !== ""
                        horizontalAlignment: Text.AlignHCenter
                        padding: 5
                        color: Runtime.colors.primary.c700.text
                        font.bold: true
                    }

                    ListView {
                        id: groupsView
                        FlickScrollSpeedControl.factor: Runtime.workspaceSettings.flickScrollSpeedFactor
                        anchors.left: parent.left
                        anchors.top: innerTitleText.visible ? innerTitleText.bottom : parent.top
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 5
                        clip: true
                        model: sceneGroup
                        keyNavigationEnabled: false
                        section.property: "category"
                        section.criteria: ViewSection.FullString
                        section.delegate: Rectangle {
                            width: groupsView.width - (groupsView.scrollBarVisible ? 20 : 1)
                            height: 30
                            color: Runtime.colors.primary.windowColor
                            VclLabel {
                                id: categoryLabel
                                text: section
                                topPadding: 5
                                bottomPadding: 5
                                anchors.centerIn: parent
                                color: Runtime.colors.primary.button.text
                                font.pointSize: Runtime.idealFontMetrics.font.pointSize
                            }
                        }
                        property bool scrollBarVisible: groupsView.height < groupsView.contentHeight
                        ScrollBar.vertical: VclScrollBar { flickable: groupsView }
                        property bool showingFilteredItems: sceneGroup.hasSceneActs && sceneGroup.hasGroupActs
                        onShowingFilteredItemsChanged: adjustScrollingLater()

                        function adjustScrolling() {
                            if(!showingFilteredItems) {
                                positionViewAtBeginning()
                                return
                            }

                            var prefCategory = Scrite.document.structure.preferredGroupCategory

                            var acts = sceneGroup.sceneActs
                            var index = -1
                            for(var i=0; i<sceneGroup.count; i++) {
                                var item = sceneGroup.at(i)

                                if(item.category.toUpperCase() !== prefCategory)
                                    continue

                                if( item.act === "" || acts.indexOf(item.act) >= 0) {
                                    positionViewAtIndex(i, ListView.Beginning)
                                    return
                                }
                            }
                        }

                        function adjustScrollingLater() {
                            Utils.execLater(groupsView, 50, adjustScrolling)
                        }

                        delegate: Rectangle {
                            width: groupsView.width - (groupsView.scrollBarVisible ? 20 : 1)
                            height: 30
                            color: groupItemMouseArea.containsMouse ? Runtime.colors.primary.button.background : Qt.rgba(0,0,0,0)
                            opacity: groupsView.showingFilteredItems ? (filtered ? 1 : 0.5) : 1
                            property bool doesNotBelongToAnyAct: arrayItem.act === ""
                            property bool filtered: doesNotBelongToAnyAct || sceneGroup.sceneActs.indexOf(arrayItem.act) >= 0

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 5

                                Image {
                                    opacity: {
                                        switch(arrayItem.checked) {
                                        case "no": return 0
                                        case "partial": return 0.25
                                        case "yes": return 1
                                        }
                                        return 0
                                    }
                                    source: "qrc:/icons/navigation/check.png"
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 24; height: 24
                                }

                                VclLabel {
                                    text: arrayItem.label
                                    width: parent.width - parent.spacing - 24
                                    anchors.verticalCenter: parent.verticalCenter
                                    font.bold: groupsView.showingFilteredItems ? filtered : doesNotBelongToAnyAct
                                    font.pointSize: Runtime.idealFontMetrics.font.pointSize
                                    leftPadding: arrayItem.type > 0 ? 20 : 0
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: groupItemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    sceneGroup.toggle(index)
                                    structureGroupsMenu.toggled(index, arrayItem.name)
                                    Scrite.user.logActivity2("structure", "tag: " + arrayItem.name)
                                }
                            }
                        }
                    }
                }

                VclButton {
                    Layout.alignment: Qt.AlignRight

                    text: "Customise"
                    onClicked: StructureStoryBeatsDialog.launch()
                }
            }

            DisabledFeatureNotice {
                anchors.fill: parent
                color: Qt.rgba(1,1,1,0.8)
                visible: !Runtime.appFeatures.structure.enabled
                featureName: "Structure Tagging"
                onClicked: structureGroupsMenu.close()
            }
        }
    }
}
