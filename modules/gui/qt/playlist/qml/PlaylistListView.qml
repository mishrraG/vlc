/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import QtQml.Models 2.2
import QtGraphicalEffects 1.0

import org.videolan.vlc 0.1

import "qrc:///widgets/" as Widgets
import "qrc:///util/KeyHelper.js" as KeyHelper
import "qrc:///style/"

Widgets.NavigableFocusScope {
    id: root

    property var plmodel: PlaylistListModel {
        playlistId: mainctx.playlist
    }

    property int leftPadding: 0
    property int rightPadding: 0
    property alias backgroundColor: parentRect.color
    property alias mediaLibAvailable: contextMenu.medialibAvailable

    property bool forceDark: false
    property VLCColors _colors: forceDark ? vlcNightColors : VLCStyle.colors

    signal setItemDropIndicatorVisible(int index, bool isVisible, bool top)

    VLCColors {id: vlcNightColors; state: "night"}

    Rectangle {
        id: parentRect
        anchors.fill: parent
        color: _colors.banner

        //label for DnD
        Widgets.DNDLabel {
            id: dragItem
            _colors: root._colors
            color: parent.color
        }

        PlaylistMenu {
            id: overlayMenu
            anchors.fill: parent
            z: 2

            navigationParent: root
            navigationLeftItem: view

            leftPadding: root.leftPadding
            rightPadding: root.rightPadding

            //rootmenu
            Action { id:playAction;         text: i18n.qtr("Play");             onTriggered: view.onPlay(); icon.source: "qrc:///toolbar/play_b.svg" }
            Action { id:deleteAction;       text: i18n.qtr("Delete");           onTriggered: view.onDelete() }
            Action { id:clearAllAction;     text: i18n.qtr("Clear Playlist");   onTriggered: mainPlaylistController.clear() }
            Action { id:selectAllAction;    text: i18n.qtr("Select All");       onTriggered: root.plmodel.selectAll() }
            Action { id:shuffleAction;      text: i18n.qtr("Shuffle Playlist");  onTriggered: mainPlaylistController.shuffle(); icon.source: "qrc:///buttons/playlist/shuffle_on.svg" }
            Action { id:sortAction;         text: i18n.qtr("Sort");             property string subMenu: "sortmenu"}
            Action { id:selectTracksAction; text: i18n.qtr("Select Tracks");    onTriggered: view.mode = "select" }
            Action { id:moveTracksAction;   text: i18n.qtr("Move Selection");   onTriggered: view.mode = "move" }

            //sortmenu
            Action { id: sortTitleAction;   text: i18n.qtr("Tile");
                onTriggered: mainPlaylistController.sort(PlaylistControllerModel.SORT_KEY_TITLE, PlaylistControllerModel.SORT_ORDER_ASC)}
            Action { id: sortDurationAction;text: i18n.qtr("Duration");
                onTriggered: mainPlaylistController.sort(PlaylistControllerModel.SORT_KEY_DURATION, PlaylistControllerModel.SORT_ORDER_ASC)}
            Action { id: sortArtistAction;  text: i18n.qtr("Artist");
                onTriggered: mainPlaylistController.sort(PlaylistControllerModel.SORT_KEY_ARTIST, PlaylistControllerModel.SORT_ORDER_ASC)}
            Action { id: sortAlbumAction;   text: i18n.qtr("Album");
                onTriggered: mainPlaylistController.sort(PlaylistControllerModel.SORT_KEY_ALBUM, PlaylistControllerModel.SORT_ORDER_ASC)}
            Action { id: sortGenreAction;   text: i18n.qtr("Genre");
                onTriggered: mainPlaylistController.sort(PlaylistControllerModel.SORT_KEY_GENRE, PlaylistControllerModel.SORT_ORDER_ASC)}
            Action { id: sortDateAction;    text: i18n.qtr("Date");
                onTriggered: mainPlaylistController.sort(PlaylistControllerModel.SORT_KEY_DATE, PlaylistControllerModel.SORT_ORDER_ASC)}
            Action { id: sortTrackAction;   text: i18n.qtr("Track Number");
                onTriggered: mainPlaylistController.sort(PlaylistControllerModel.SORT_KEY_TRACK_NUMBER, PlaylistControllerModel.SORT_ORDER_ASC)}
            Action { id: sortURLAction;     text: i18n.qtr("URL");
                onTriggered: mainPlaylistController.sort(PlaylistControllerModel.SORT_KEY_URL, PlaylistControllerModel.SORT_ORDER_ASC)}
            Action { id: sortRatingAction;  text: i18n.qtr("Rating");
                onTriggered: mainPlaylistController.sort(PlaylistControllerModel.SORT_KEY_RATIN, PlaylistControllerModel.SORT_ORDER_ASC)}

            models: {
                "rootmenu" : {
                    title: i18n.qtr("Playlist"),
                    entries: [
                        playAction,
                        deleteAction,
                        clearAllAction,
                        selectAllAction,
                        shuffleAction,
                        sortAction,
                        selectTracksAction,
                        moveTracksAction
                    ]
                },
                "sortmenu" :{
                    title: i18n.qtr("Sort Playlist"),
                    entries:  [
                        sortTitleAction,
                        sortDurationAction,
                        sortArtistAction,
                        sortAlbumAction,
                        sortGenreAction,
                        sortDateAction,
                        sortTrackAction,
                        sortURLAction,
                        sortRatingAction,
                    ]
                }
            }
        }

        Widgets.MenuExt {
            id: contextMenu
            property alias model: root.plmodel
            property int itemIndex: -1
            property bool medialibAvailable: false
            closePolicy: Popup.CloseOnReleaseOutside | Popup.CloseOnEscape

            Widgets.MenuItemExt {
                text: i18n.qtr("Play")
                icon.source: "qrc:/toolbar/play_b.svg"
                icon.width: VLCStyle.icon_small
                icon.height: VLCStyle.icon_small
                onTriggered: {
                    mainPlaylistController.goTo(contextMenu.itemIndex, true)
                }
            }

            Widgets.MenuItemExt {
                text: i18n.qtr("Stream")
                icon.source: "qrc:/menu/stream.svg"
                icon.width: VLCStyle.icon_small
                icon.height: VLCStyle.icon_small
                onTriggered: {
                    var selection = contextMenu.model.getSelection()
                    if (selection.length === 0)
                        return

                    dialogProvider.streamingDialog(selection.map(function(i) { return contextMenu.model.itemAt(i).url; }), false)
                }
            }

            Widgets.MenuItemExt {
                text: i18n.qtr("Save")
                onTriggered: {
                    var selection = contextMenu.model.getSelection()
                    if (selection.length === 0)
                        return

                    dialogProvider.streamingDialog(selection.map(function(i) { return contextMenu.model.itemAt(i).url; }))
                }
            }

            Widgets.MenuItemExt {
                text: i18n.qtr("Information...")
                icon.source: "qrc:/menu/info.svg"
                icon.width: VLCStyle.icon_small
                icon.height: VLCStyle.icon_small
                onTriggered: {
                    dialogProvider.mediaInfoDialog(contextMenu.model.itemAt(contextMenu.itemIndex))
                }
            }

            MenuSeparator { }

            Widgets.MenuItemExt {
                text: i18n.qtr("Show Containing Directory...")
                icon.source: "qrc:/type/folder-grey.svg"
                icon.width: VLCStyle.icon_small
                icon.height: VLCStyle.icon_small
                onTriggered: {
                    mainPlaylistController.explore(contextMenu.model.itemAt(contextMenu.itemIndex))
                }
            }

            MenuSeparator { }

            Widgets.MenuItemExt {
                text: i18n.qtr("Add File...")
                icon.source: "qrc:/buttons/playlist/playlist_add.svg"
                icon.width: VLCStyle.icon_small
                icon.height: VLCStyle.icon_small
                onTriggered: {
                    dialogProvider.simpleOpenDialog(false)
                }
            }

            Widgets.MenuItemExt {
                text: i18n.qtr("Add Directory...")
                icon.source: "qrc:/buttons/playlist/playlist_add.svg"
                icon.width: VLCStyle.icon_small
                icon.height: VLCStyle.icon_small
                onTriggered: {
                    dialogProvider.PLAppendDir()
                }
            }

            Widgets.MenuItemExt {
                text: i18n.qtr("Advanced Open...")
                icon.source: "qrc:/buttons/playlist/playlist_add.svg"
                icon.width: VLCStyle.icon_small
                icon.height: VLCStyle.icon_small
                onTriggered: {
                    dialogProvider.PLAppendDialog()
                }
            }

            MenuSeparator { }

            Widgets.MenuItemExt {
                text: i18n.qtr("Save Playlist to File...")
                onTriggered: {
                    dialogProvider.savePlayingToPlaylist();
                }
            }

            MenuSeparator { }

            Widgets.MenuItemExt {
                text: i18n.qtr("Remove Selected")
                icon.source: "qrc:/buttons/playlist/playlist_remove.svg"
                icon.width: VLCStyle.icon_small
                icon.height: VLCStyle.icon_small
                onTriggered: {
                    contextMenu.model.removeItems(contextMenu.model.getSelection())
                }
            }

            Widgets.MenuItemExt {
                text: i18n.qtr("Clear the playlist")
                icon.source: "qrc:/toolbar/clear.svg"
                icon.width: VLCStyle.icon_small
                icon.height: VLCStyle.icon_small
                onTriggered: {
                    mainPlaylistController.clear()
                }
            }

            MenuSeparator { }

            onClosed: contextMenu.parent.forceActiveFocus()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.bottomMargin: VLCStyle.margin_normal

            ColumnLayout {
                id: headerTextLayout
                Layout.fillWidth: true
                Layout.leftMargin: root.leftPadding + VLCStyle.margin_normal
                Layout.topMargin: VLCStyle.margin_normal

                Widgets.SubtitleLabel {
                    text: i18n.qtr("Playqueue")
                    color: _colors.text
                }

                Widgets.CaptionLabel {
                    anchors.topMargin: VLCStyle.margin_small
                    visible: plmodel.count !== 0
                    text: i18n.qtr("%1 elements, %2 min").arg(root.plmodel.count).arg(plmodel.duration.toMinutes())
                    color: _colors.caption
                }
            }

            RowLayout {
                id: content
                visible: plmodel.count !== 0

                Layout.topMargin: VLCStyle.margin_normal
                Layout.leftMargin: root.leftPadding + VLCStyle.margin_normal
                Layout.rightMargin: root.rightPadding + view.scrollBarWidth

                Widgets.IconLabel {
                    Layout.preferredWidth: VLCStyle.icon_normal
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: VLCIcons.album_cover
                    color: _colors.caption
                }

                Widgets.CaptionLabel {
                    Layout.fillWidth: true
                    Layout.leftMargin: VLCStyle.margin_large
                    verticalAlignment: Text.AlignVCenter
                    text: i18n.qtr("Title")
                    color: _colors.caption
                }

                Widgets.IconLabel {
                    Layout.rightMargin: VLCStyle.margin_xsmall
                    Layout.preferredWidth: durationMetric.width

                    text: VLCIcons.time
                    color: _colors.caption
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    TextMetrics {
                        id: durationMetric
                        font.pixelSize: VLCStyle.fontSize_normal
                        text: "-00:00-"
                    }
                }
            }

            Widgets.KeyNavigableListView {
                id: view

                Layout.fillWidth: true
                Layout.fillHeight: true

                focus: true

                model: root.plmodel
                modelCount: root.plmodel.count

                fadeColor: root.backgroundColor

                property int shiftIndex: -1
                property string mode: "normal"

                Connections {
                    target: root.plmodel
                    onRowsInserted: {
                        if (view.currentIndex == -1)
                            view.currentIndex = 0
                    }
                    onModelReset: {
                        if (view.currentIndex == -1 &&  root.plmodel.count > 0)
                            view.currentIndex = 0
                    }
                    onSelectedCountChanged: {
                        var selectedIndexes = root.plmodel.getSelection()
                        var modelCount = root.plmodel.count

                        if (modelCount === 0 || selectedIndexes.length === 0)
                            return

                        var bottomItemIndex = view.listView.indexAt(view.listView.contentX, (view.listView.contentY + view.height) - 2)
                        var topItemIndex    = view.listView.indexAt(view.listView.contentX, view.listView.contentY + 2)

                        if (topItemIndex !== -1 && (root.plmodel.isSelected(topItemIndex) || (modelCount >= 2 && root.plmodel.isSelected(topItemIndex + 1))))
                            view.fadeRectTopHovered = true
                        else
                            view.fadeRectTopHovered = false

                        if (bottomItemIndex !== -1 && (root.plmodel.isSelected(bottomItemIndex) || (root.plmodel.isSelected(bottomItemIndex - 1))))
                            view.fadeRectBottomHovered = true
                        else
                            view.fadeRectBottomHovered = false
                    }
                }

                footer: Item {
                    width: parent.width
                    height: Math.max(VLCStyle.icon_normal, view.height - y)

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton | Qt.LeftButton

                        onClicked: {
                            if( mouse.button === Qt.RightButton )
                            {
                                view.forceActiveFocus()
                                root.plmodel.deselectAll()
                                contextMenu.itemIndex = -1
                                contextMenu.popup()
                            }
                            else if ( mouse.button === Qt.LeftButton )
                            {
                                view.forceActiveFocus()
                                root.plmodel.deselectAll()
                            }
                        }
                    }

                    DropArea {
                        anchors.fill: parent
                        onEntered: {
                            if(drag.source.model.index === root.plmodel.count - 1)
                                return

                            root.setItemDropIndicatorVisible(view.modelCount - 1, true, false);
                        }
                        onExited: {
                            if(drag.source.model.index === root.plmodel.count - 1)
                                return

                            root.setItemDropIndicatorVisible(view.modelCount - 1, false, false);
                        }
                        onDropped: {
                            if(drag.source.model.index === root.plmodel.count - 1)
                                return

                            if (drop.hasUrls) {
                                //force conversion to an actual list
                                var urlList = []
                                for ( var url in drop.urls)
                                    urlList.push(drop.urls[url])
                                mainPlaylistController.insert(root.plmodel.count, urlList)
                            } else {
                                root.plmodel.moveItemsPost(root.plmodel.getSelection(), root.plmodel.count - 1)
                            }
                            root.setItemDropIndicatorVisible(view.modelCount - 1, false, false);
                            drop.accept()
                        }
                    }
                }

                delegate: Column {

                    Loader {
                        active: (index === 0) // load only for the first element to prevent overlapping
                        width: parent.width
                        height: 1
                        z: 0
                        sourceComponent: Rectangle {
                            color: _colors.playlistSeparator
                            opacity: _colors.isThemeDark ? 0.05 : 1.0
                        }
                    }

                    PLItem {
                        /*
                         * implicit variables:
                         *  - model: gives access to the values associated to PlaylistListModel roles
                         *  - index: the index of this item in the list
                         */
                        id: plitem
                        plmodel: root.plmodel
                        width: root.width
                        z: 1
                        leftPadding: root.leftPadding + VLCStyle.margin_normal
                        rightPadding: root.rightPadding + view.scrollBarWidth

                        onItemClicked : {
                            /* to receive keys events */
                            view.forceActiveFocus()
                            if (view.mode == "move") {
                                var selectedIndexes = root.plmodel.getSelection()
                                if (selectedIndexes.length === 0)
                                    return
                                var preTarget = index
                                /* move to _above_ the clicked item if move up, but
                                 * _below_ the clicked item if move down */
                                if (preTarget > selectedIndexes[0])
                                    preTarget++
                                view.currentIndex = selectedIndexes[0]
                                root.plmodel.moveItemsPre(selectedIndexes, preTarget)
                                return
                            } else if (view.mode == "select") {
                            } else if (!(root.plmodel.isSelected(index) && button === Qt.RightButton)) {
                                view.updateSelection(modifier, view.currentIndex, index)
                                view.currentIndex = index
                            }

                            if (button === Qt.RightButton)
                            {
                                contextMenu.itemIndex = index
                                contextMenu.popup()
                            }
                        }
                        onItemDoubleClicked: mainPlaylistController.goTo(index, true)
                        color: _colors.getBgColor(model.selected, plitem.hovered, plitem.activeFocus)
                        _colors: root._colors

                        onDragStarting: {
                            if (!root.plmodel.isSelected(index)) {
                                /* the dragged item is not in the selection, replace the selection */
                                root.plmodel.setSelection([index])
                            }
                        }

                        onDropedMovedAt: {
                            if (drop.hasUrls) {
                                //force conversion to an actual list
                                var urlList = []
                                for ( var url in drop.urls)
                                    urlList.push(drop.urls[url])
                                mainPlaylistController.insert(target, urlList)
                            } else {
                                root.plmodel.moveItemsPre(root.plmodel.getSelection(), target)
                            }
                        }

                        onHoveredChanged: {
                            var bottomItemIndex = view.listView.indexAt(plitem.width / 2, (view.listView.contentY + view.height) - 2)
                            var topItemIndex = view.listView.indexAt(plitem.width / 2, view.listView.contentY + 2)

                            if(bottomItemIndex !== -1 && model.index >= bottomItemIndex - 1)
                            {
                                view.fadeRectBottomHovered = plitem.hovered
                            }
                            if(topItemIndex !== -1 && model.index <= topItemIndex + 1)
                            {
                                view.fadeRectTopHovered = plitem.hovered
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        z: 0
                        color: _colors.playlistSeparator
                        opacity: _colors.isThemeDark ? 0.05 : 1.0
                    }
                }

                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 200 }
                }

                displaced: Transition {
                    NumberAnimation { properties: "x,y"; duration: 200; easing.type: Easing.OutSine }
                    NumberAnimation { property: "opacity"; to: 1.0 }
                }

                onSelectAll: root.plmodel.selectAll()
                onSelectionUpdated: {
                    if (view.mode === "select") {
                        console.log("update selection select")
                    } else if (mode == "move") {
                        var selectedIndexes = root.plmodel.getSelection()
                        if (selectedIndexes.length === 0)
                            return
                        /* always move relative to the first item of the selection */
                        var target = selectedIndexes[0];
                        if (newIndex > oldIndex) {
                            /* move down */
                            target++
                        } else if (newIndex < oldIndex && target > 0) {
                            /* move up */
                            target--
                        }

                        view.currentIndex = selectedIndexes[0]
                        /* the target is the position _after_ the move is applied */
                        root.plmodel.moveItemsPost(selectedIndexes, target)
                    } else { // normal
                        updateSelection(keyModifiers, oldIndex, newIndex);
                    }
                }

                Keys.onDeletePressed: onDelete()
                Keys.onMenuPressed: overlayMenu.open()

                navigationParent: root
                navigationRight: function(index) {
                    overlayMenu.open()
                }
                navigationLeft: function(index) {
                    if (mode === "normal") {
                        root.navigationLeft(index)
                    } else {
                        mode = "normal"
                    }
                }
                navigationCancel: function(index) {
                    if (mode === "normal") {
                        root.navigationCancel(index)
                    } else {
                        mode = "normal"
                    }
                }

                onActionAtIndex: {
                    if (index < 0)
                        return

                    if (mode === "select")
                        root.plmodel.toggleSelected(index)
                    else //normal
                        // play
                        mainPlaylistController.goTo(index, true)
                }

                function onPlay() {
                    let selection = root.plmodel.getSelection()
                    if (selection.length === 0)
                        return
                    mainPlaylistController.goTo(selection[0], true)
                }

                function onDelete() {
                    let selection = root.plmodel.getSelection()
                    if (selection.length === 0)
                        return
                    root.plmodel.removeItems(selection)
                }

                function _addRange(from, to) {
                    root.plmodel.setRangeSelected(from, to - from + 1, true)
                }

                function _delRange(from, to) {
                    root.plmodel.setRangeSelected(from, to - from + 1, false)
                }

                // copied from SelectableDelegateModel, which is intended to be removed
                function updateSelection( keymodifiers, oldIndex, newIndex ) {
                    if ((keymodifiers & Qt.ShiftModifier)) {
                        if ( shiftIndex === oldIndex) {
                            if ( newIndex > shiftIndex )
                                _addRange(shiftIndex, newIndex)
                            else
                                _addRange(newIndex, shiftIndex)
                        } else if (shiftIndex <= newIndex && newIndex < oldIndex) {
                            _delRange(newIndex + 1, oldIndex )
                        } else if ( shiftIndex < oldIndex && oldIndex < newIndex ) {
                            _addRange(oldIndex, newIndex)
                        } else if ( newIndex < shiftIndex && shiftIndex < oldIndex ) {
                            _delRange(shiftIndex, oldIndex)
                            _addRange(newIndex, shiftIndex)
                        } else if ( newIndex < oldIndex && oldIndex < shiftIndex  ) {
                            _addRange(newIndex, oldIndex)
                        } else if ( oldIndex <= shiftIndex && shiftIndex < newIndex ) {
                            _delRange(oldIndex, shiftIndex)
                            _addRange(shiftIndex, newIndex)
                        } else if ( oldIndex < newIndex && newIndex <= shiftIndex  ) {
                            _delRange(oldIndex, newIndex - 1)
                        }
                    } else {
                        shiftIndex = newIndex
                        if (keymodifiers & Qt.ControlModifier) {
                            root.plmodel.toggleSelected(newIndex)
                        } else {
                            root.plmodel.setSelection([newIndex])
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    visible: plmodel.count === 0

                    Widgets.IconLabel {
                        font.pixelSize: VLCStyle.dp(48)
                        anchors.horizontalCenter: parent.horizontalCenter
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: VLCIcons.playlist
                        color: view.activeFocus ? _colors.accent : _colors.text
                        opacity: 0.3
                    }

                    // ToDo: Use TitleLabel
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.topMargin: VLCStyle.margin_xlarge
                        text: i18n.qtr("No content yet")
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: VLCStyle.fontSize_xxlarge
                        color: view.activeFocus ? _colors.accent : _colors.text
                        opacity: 0.4
                    }

                    // ToDo: Use BodyLabel
                    Label {
                        anchors.topMargin: VLCStyle.margin_normal
                        text: i18n.qtr("Drag & Drop some content here!")
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: VLCStyle.fontSize_large
                        color: view.activeFocus ? _colors.accent : _colors.text
                        opacity: 0.4
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                height: VLCStyle.heightBar_normal
                visible: !(infoText.text === "")

	            RectangularGlow {
	                anchors.top: parent.top
	                anchors.bottom: parent.bottom
	                anchors.horizontalCenter: parent.horizontalCenter

	                width: infoText.width + VLCStyle.dp(18)
	                height: infoText.height + VLCStyle.dp(12)

	                glowRadius: 2
	                cornerRadius: 10
	                spread: 0.1
	                color: _colors.glowColorBanner
	            }

                Label {
                    id: infoText
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter

                    text: (view.mode === "select")
                            ? i18n.qtr("Select tracks (%1)").arg(plmodel.selectedCount)
                        : (view.mode === "move")
                            ? i18n.qtr("Move tracks (%1)").arg(plmodel.selectedCount)
                        : ""
                    font.pixelSize: VLCStyle.fontSize_large
                    color: _colors.text
                    elide: Text.ElideRight
                }
            }

            PlaylistToolbar {
                Layout.fillWidth: true

                leftPadding: root.leftPadding
                rightPadding: root.rightPadding
                navigationParent: root
                navigationUpItem: view

                _colors: root._colors
            }
        }
    }

    Keys.priority: Keys.AfterItem
    Keys.forwardTo: view
    Keys.onPressed: {
        if (event.matches(StandardKey.SelectAll))
        {
            root.plmodel.selectAll();
        }
        else
        {
            defaultKeyAction(event, 0)
        }
    }
}
