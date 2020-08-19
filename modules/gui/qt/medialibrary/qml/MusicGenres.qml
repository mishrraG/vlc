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
import QtQml.Models 2.2
import org.videolan.vlc 0.1
import org.videolan.medialib 0.1

import "qrc:///util/" as Util
import "qrc:///widgets/" as Widgets
import "qrc:///style/"

Widgets.NavigableFocusScope {
    id: root
    property alias model: genreModel
    property var sortModel: [
        { text: i18n.qtr("Alphabetic"), criteria: "title" }
    ]

    readonly property var currentIndex: view.currentItem.currentIndex
    //the index to "go to" when the view is loaded
    property var initialIndex: 0

    onInitialIndexChanged:  resetFocus()

    navigationCancel: function() {
        if (view.currentItem.currentIndex <= 0)
            defaultNavigationCancel()
        else
            view.currentItem.currentIndex = 0;
    }

    Component.onCompleted: loadView()

    function loadView() {
        if (medialib.gridView) {
            view.replace(gridComponent)
        } else {
            view.replace(tableComponent)
        }
    }

    function showAlbumView( m ) {
        history.push([ "mc", "music", "genres", "albums", { parentId: m.id, genreName: m.name } ])
    }

    function resetFocus() {
        if (genreModel.count === 0) {
            return
        }
        var initialIndex = root.initialIndex
        if (initialIndex >= genreModel.count)
            initialIndex = 0
        selectionModel.select(genreModel.index(initialIndex, 0), ItemSelectionModel.ClearAndSelect)
        view.currentItem.positionViewAtIndex(initialIndex, ItemView.Contain)
    }

    Connections {
        target: medialib
        onGridViewChanged: loadView()
    }

    MLGenreModel {
        id: genreModel
        ml: medialib

        onCountChanged: {
            if (genreModel.count > 0 && !selectionModel.hasSelection) {
                root.resetFocus()
            }
        }
    }

    Widgets.MenuExt {
        id: contextMenu
        property var model: ({})
        closePolicy: Popup.CloseOnReleaseOutside | Popup.CloseOnEscape
        onClosed: contextMenu.parent.forceActiveFocus()

        Widgets.MenuItemExt {
            id: playMenuItem
            text: "Play from start"
            onTriggered: {
                medialib.addAndPlay( contextMenu.model.id )
                history.push(["player"])
            }
        }

        Widgets.MenuItemExt {
            text: "Enqueue"
            onTriggered: medialib.addToPlaylist( contextMenu.model.id )
        }
    }

    function _actionAtIndex(index) {
        if (selectionModel.selectedIndexes.length > 1) {
            medialib.addAndPlay(model.getIdsForIndexes(selectionModel.selectedIndexes))
        } else if (selectionModel.selectedIndexes.length === 1) {
            var sel = selectionModel.selectedIndexes[0]
            showAlbumView( genreModel.getDataAt(sel) )
        }
    }

    Util.SelectableDelegateModel {
        id: selectionModel

        model: genreModel
    }

    /*
     *define the intial position/selection
     * This is done on activeFocus rather than Component.onCompleted because selectionModel.
     * selectedGroup update itself after this event
     */
    onActiveFocusChanged: {
        if (activeFocus && genreModel.count > 0 && !selectionModel.hasSelection) {
            var initialIndex = 0
            if (view.currentItem.currentIndex !== -1)
                initialIndex = view.currentItem.currentIndex
            selectionModel.select(genreModel.index(initialIndex, 0), ItemSelectionModel.ClearAndSelect)
            view.currentItem.currentIndex = initialIndex
        }
    }

    /* Grid View */
    Component {
        id: gridComponent
        Widgets.ExpandGridView {
            id: gridView_id

            delegateModel: selectionModel
            model: genreModel
            topMargin: VLCStyle.margin_large

            delegate: Widgets.GridItem {
                id: item

                property var model: ({})
                property int index: -1

                width: VLCStyle.colWidth(2)
                height: width / 2
                pictureWidth: width
                pictureHeight: height
                image: model.cover || VLCStyle.noArtAlbum
                playCoverBorder.width: VLCStyle.dp(3, VLCStyle.scale)

                onItemDoubleClicked: root.showAlbumView(model)
                onItemClicked: {
                    selectionModel.updateSelection( modifier , view.currentItem.currentIndex, index)
                    view.currentItem.currentIndex = index
                    view.currentItem.forceActiveFocus()
                }
                onPlayClicked: {
                    if (model.id)
                        medialib.addAndPlay(model.id)
                }

                Column {
                    anchors.centerIn: parent
                    opacity: item._highlighted ? .3 : 1

                    Label {
                         width: item.width
                         elide: Text.ElideRight
                         font.pixelSize: VLCStyle.fontSize_large
                         font.weight: Font.DemiBold
                         text: model.name
                         color: "white"
                         horizontalAlignment: Text.AlignHCenter
                    }

                    Widgets.CaptionLabel {
                        width: item.width
                        text: model.nb_tracks > 1 ? i18n.qtr("%1 Tracks").arg(model.nb_tracks) : i18n.qtr("%1 Track").arg(model.nb_tracks)
                        opacity: .7
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            focus: true

            cellWidth: VLCStyle.colWidth(2)
            cellHeight: cellWidth / 2

            onSelectAll: selectionModel.selectAll()
            onSelectionUpdated:  selectionModel.updateSelection( keyModifiers, oldIndex, newIndex )
            onActionAtIndex: _actionAtIndex(index)

            navigationParent: root
        }
    }

    Component {
        id: tableComponent
        /* Table View */
        Widgets.KeyNavigableTableView {
            id: tableView_id

            readonly property int _nameColSpan: Math.max(
                                                    VLCStyle.gridColumnsForWidth(tableView_id.availableRowWidth - VLCStyle.listAlbumCover_width - VLCStyle.column_margin_width) - 1
                                                    , 1)

            property Component thumbnailHeader: Item {
                Widgets.IconLabel {
                    height: VLCStyle.listAlbumCover_height
                    width: VLCStyle.listAlbumCover_width
                    horizontalAlignment: Text.AlignHCenter
                    text: VLCIcons.album_cover
                    color: VLCStyle.colors.caption
                }
            }

            property Component thumbnailColumn: Item {

                property var rowModel: parent.rowModel
                property var model: parent.colModel
                readonly property bool currentlyFocused: parent.currentlyFocused
                readonly property bool containsMouse: parent.containsMouse

                Widgets.MediaCover {
                    anchors.verticalCenter: parent.verticalCenter
                    source: ( !rowModel ? undefined : rowModel[model.criteria] ) || VLCStyle.noArtCover
                    playCoverVisible: currentlyFocused || containsMouse
                    playIconSize: VLCStyle.play_cover_small
                    onPlayIconClicked:  medialib.addAndPlay( rowModel.id )
                }
            }

            model: genreModel
            headerColor: VLCStyle.colors.bg
            focus: true
            onActionForSelection: _actionAtIndex(selection)
            navigationParent: root

            sortModel:  [
                { isPrimary: true, criteria: "cover", width: VLCStyle.listAlbumCover_width, headerDelegate: thumbnailHeader, colDelegate: thumbnailColumn },
                { criteria: "name", width: VLCStyle.colWidth(tableView_id._nameColSpan), text: i18n.qtr("Name") },
                { criteria: "nb_tracks", width: VLCStyle.colWidth(1), text: i18n.qtr("Tracks") }
            ]

            onItemDoubleClicked: {
                root.showAlbumView(model)
            }

            onContextMenuButtonClicked: {
                contextMenu.model = menuModel
                contextMenu.popup(menuParent)
            }
        }
    }

    Widgets.StackViewExt {
        id: view

        initialItem: medialib.gridView ? gridComponent : tableComponent

        anchors.fill: parent
        focus: genreModel.count !== 0
    }
}
