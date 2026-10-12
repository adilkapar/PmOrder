@EndUserText.label: 'Maintenance Order Component - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZC_PM_ORDER_OPERATION as projection on ZR_PM_ORDER_OPERATION
{
@UI.hidden: true
  key MaintOrderRoutingNumber,
  key MaintenanceOrderOperation,
  key MaintenanceOrder, 
      OperationDescription,
      Plant,
      Equipment,
      FunctionalLocation,
      FunctionalArea,
      OperationWorkCenterInternalID,
      OperationWorkCenterTypeCode,      
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_PM_BM_WorkCenter', element: 'WorkCenter' },
      additionalBinding: [
          { localElement: 'Plant', element: 'Plant' } ] } ]      
      WorkCenter,
      WorkCenterText,
      // Associations
      _MaintenanceOrder,
      _Plant,
      
      _Order : redirected to parent ZC_PM_ORDER
}