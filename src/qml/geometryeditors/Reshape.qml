import QtQuick 2.14

import org.qgis 1.0
import org.qfield 1.0
import Theme 1.0
import ".."

VisibilityFadingRow {
    id: reshapeToolbar

    signal finished()

    property FeatureModel featureModel
    property bool screenHovering: false //<! if the stylus pen is used, one should not use the add button

    readonly property bool blocking: drawPolygonToolbar.isDigitizing

    spacing: 4

    function canvasClicked(point)
    {
        drawPolygonToolbar.addVertex();
        return true; // handled
    }

    function canvasLongPressed(point)
    {
        drawPolygonToolbar.confirm();
        return true; // handled
    }

    DigitizingToolbar {
        id: drawPolygonToolbar
        showConfirmButton: true
        screenHovering: reshapeToolbar.screenHovering

        digitizingLogger.type: 'edit_reshape'

        onConfirmed: {
            digitizingLogger.writeCoordinates()

            rubberbandModel.frozen = true
            if (!featureModel.currentLayer.editBuffer())
                featureModel.currentLayer.startEditing()
            var result = GeometryUtils.reshapeFromRubberband(featureModel.currentLayer, featureModel.feature.id, rubberbandModel)
            if ( result !== GeometryUtils.Success )
            {
                displayToast( qsTr( 'The geometry could not be reshaped' ), 'error' );
                featureModel.currentLayer.rollBack()
                rubberbandModel.reset()
            }
            else
            {
                featureModel.currentLayer.commitChanges()
                rubberbandModel.reset()
                featureModel.refresh()
                featureModel.applyGeometryToVertexModel()
            }
        }

        onCancel: {
          rubberbandModel.reset()
        }
    }

    function init(featureModel, mapSettings, editorRubberbandModel, editorRenderer)
    {
        reshapeToolbar.featureModel = featureModel
        drawPolygonToolbar.digitizingLogger.digitizingLayer = featureModel.currentLayer
        drawPolygonToolbar.rubberbandModel = editorRubberbandModel
        drawPolygonToolbar.rubberbandModel.geometryType = Qgis.GeometryType.Polygon
        drawPolygonToolbar.mapSettings = mapSettings
        drawPolygonToolbar.stateVisible = true
    }

    function cancel()
    {
        drawPolygonToolbar.cancel()
    }
}
