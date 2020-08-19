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
import QtQuick.Controls 2.4
import QtQuick 2.11
import QtQml.Models 2.2
import QtQuick.Layouts 1.3

import org.videolan.medialib 0.1

import "qrc:///util/" as Util
import "qrc:///widgets/" as Widgets
import "qrc:///style/"


Widgets.NavigableFocusScope {
    id: root

    //name and properties of the tab to be initially loaded
    property string view: "all"
    property var viewProperties: ({})
    property var model

    readonly property var pageModel: [{
        name: "all",
        component: artistGridComponent
    }, {
        name: "albums",
        component: artistAlbumsComponent
    }]

    Component.onCompleted: loadView()
    onViewChanged: {
        viewProperties = {}
        loadView()
    }
    onViewPropertiesChanged: loadView()

    function loadDefaultView() {
        root.view = "all"
        root.viewProperties= ({})
    }

    function loadView() {
        var found = stackView.loadView(root.pageModel, view, viewProperties)
        if (!found)
            stackView.replace(root.pageModel[0].component)
        stackView.currentItem.navigationParent = root
        model = stackView.currentItem.model
    }

    function _updateArtistsAllHistory(currentIndex) {
        history.update(["mc", "music", "artists", "all", { "initialIndex": currentIndex }])
    }

    function _updateArtistsAlbumsHistory(currentIndex, initialAlbumIndex) {
        history.update(["mc","music", "artists", "albums", {
            "initialIndex": currentIndex,
            "initialAlbumIndex": initialAlbumIndex,
        }])
    }

    Component {
        id: artistGridComponent

        Widgets.NavigableFocusScope {
            id: artistAllView

            readonly property int currentIndex: view.currentItem.currentIndex
            property int initialIndex: 0
            property alias model: artistModel

            onCurrentIndexChanged: {
                _updateArtistsAllHistory(currentIndex)
            }

            onInitialIndexChanged: resetFocus()

            function showAlbumView() {
                history.push([ "mc", "music", "artists", "albums", { initialIndex: artistAllView.currentIndex } ])
            }

            function resetFocus() {
                if (artistModel.count === 0) {
                    return
                }
                var initialIndex = artistAllView.initialIndex
                if (initialIndex >= artistModel.count)
                    initialIndex = 0
                selectionModel.select(artistModel.index(initialIndex, 0), ItemSelectionModel.ClearAndSelect)
                view.currentItem.currentIndex = initialIndex
                view.currentItem.positionViewAtIndex(initialIndex, ItemView.Contain)
            }

            MLArtistModel {
                id: artistModel
                ml: medialib

                onCountChanged: {
                    if (artistModel.count > 0 && !selectionModel.hasSelection) {
                        artistAllView.resetFocus()
                    }
                }
            }

            Util.SelectableDelegateModel {
                id: selectionModel
                model: artistModel
            }

            Widgets.MenuExt {
                id: contextMenu
                property var model: ({})
                closePolicy: Popup.CloseOnReleaseOutside | Popup.CloseOnEscape

                Widgets.MenuItemExt {
                    id: playMenuItem
                    text: i18n.qtr("Play")
                    onTriggered: {
                        medialib.addAndPlay( contextMenu.model.id )
                        history.push(["player"])
                    }
                }

                Widgets.MenuItemExt {
                    text: "Enqueue"
                    onTriggered: medialib.addToPlaylist( contextMenu.model.id )
                }

                onClosed: contextMenu.parent.forceActiveFocus()

            }

            Component {
                id: gridComponent

                Widgets.ExpandGridView {
                    id: artistGrid

                    anchors.fill: parent
                    topMargin: VLCStyle.margin_large
                    delegateModel: selectionModel
                    model: artistModel
                    focus: true
                    cellWidth: VLCStyle.colWidth(1)
                    cellHeight: VLCStyle.gridItem_music_height
                    onSelectAll: selectionModel.selectAll()
                    onSelectionUpdated: selectionModel.updateSelection( keyModifiers, oldIndex, newIndex )
                    navigationParent: root

                    onActionAtIndex: {
                        if (selectionModel.selectedIndexes.length > 1) {
                            medialib.addAndPlay( artistModel.getIdsForIndexes( selectionModel.selectedIndexes ) )
                        } else {
                            view.currentItem.currentIndex = index
                            showAlbumView()
                            medialib.addAndPlay( artistModel.getIdForIndex(index) )
                        }
                    }

                    delegate: AudioGridItem {
                        id: gridItem

                        title: model.name
                        subtitle: model.nb_tracks > 1 ? i18n.qtr("%1 songs").arg(model.nb_tracks) : i18n.qtr("%1 song").arg(model.nb_tracks)
                        pictureRadius: VLCStyle.artistGridCover_radius
                        pictureHeight: VLCStyle.artistGridCover_radius
                        pictureWidth: VLCStyle.artistGridCover_radius
                        playCoverBorder.width: VLCStyle.dp(3, VLCStyle.scale)
                        titleMargin: VLCStyle.margin_xlarge
                        playIconSize: VLCStyle.play_cover_small
                        textHorizontalAlignment: Text.AlignHCenter
                        width: VLCStyle.colWidth(1)

                        onItemClicked: {
                            selectionModel.updateSelection( modifier , view.currentItem.currentIndex, index )
                            view.currentItem.currentIndex = index
                            view.currentItem.forceActiveFocus()
                        }

                        onItemDoubleClicked: artistAllView.showAlbumView(model)
                    }
                }
            }



            Component {
                id: tableComponent

                Widgets.KeyNavigableTableView {
                    id: artistTable

                    readonly property int _nbCols: VLCStyle.gridColumnsForWidth(artistTable.availableRowWidth)

                    anchors.fill: parent
                    model: artistModel
                    focus: true
                    headerColor: VLCStyle.colors.bg
                    navigationParent: root

                    onActionForSelection: {
                        if (selection.length > 1) {
                            medialib.addAndPlay( artistModel.getIdsForIndexes( selection ) )
                        } else {
                            showAlbumView()
                            medialib.addAndPlay( artistModel.getIdForIndex(index) )
                        }
                    }

                    sortModel:  [
                        { isPrimary: true, criteria: "name", width: VLCStyle.colWidth(Math.max(artistTable._nbCols - 1, 1)), text: i18n.qtr("Name"), headerDelegate: tableColumns.titleHeaderDelegate, colDelegate: tableColumns.titleDelegate },
                        { criteria: "nb_tracks", width: VLCStyle.colWidth(1), text: i18n.qtr("Tracks") }
                    ]

                    onItemDoubleClicked: {
                        artistAllView.showAlbumView(model)
                    }

                    onContextMenuButtonClicked: {
                        contextMenu.model = menuModel
                        contextMenu.popup(menuParent)
                    }

                    Widgets.TableColumns {
                        id: tableColumns
                    }
                }
            }

            Widgets.StackViewExt {
                id: view

                anchors.fill: parent
                focus: true
                initialItem: medialib.gridView ? gridComponent : tableComponent
            }

            Connections {
                target: medialib
                onGridViewChanged: {
                    if (medialib.gridView) {
                        view.replace(gridComponent)
                    } else {
                        view.replace(tableComponent)
                    }
                }
            }

            EmptyLabel {
                anchors.fill: parent
                visible: artistModel.count === 0
                text: i18n.qtr("No artists found\nPlease try adding sources, by going to the Network tab")
                navigationParent: root
            }
        }
    }

    Component {
        id: artistAlbumsComponent
        /* List View */
        MusicArtistsAlbums {
            onCurrentIndexChanged: _updateArtistsAlbumsHistory(currentIndex, currentAlbumIndex)
            onCurrentAlbumIndexChanged: _updateArtistsAlbumsHistory(currentIndex, currentAlbumIndex)
        }
    }

    Widgets.StackViewExt {
        id: stackView

        anchors.fill: parent
        focus: true
    }
}
