@EndUserText.label: 'Maintenance Order Operation - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity ZR_PM_ORDER_OPERATION
  as select from    I_MaintenanceOrderOperation as operation

    left outer join ZI_PM_BM_WorkCenter         as WC on WC.WorkCenterID = operation.OperationWorkCenterInternalID
  association to parent ZR_PM_ORDER as _Order on $projection.MaintenanceOrder = _Order.MaintenanceOrder
  association to I_StatusObjectActiveStatus     as _StatusObjectActiveStatus     on  operation.MaintOrderOperationInternalID = _StatusObjectActiveStatus.StatusObject and _StatusObjectActiveStatus.StatusCode  = 'I0013'
{
  key operation.MaintOrderRoutingNumber,
  key cast ( operation.MaintenanceOrderOperation as char4 ) as MaintenanceOrderOperation,
  key operation.MaintenanceOrder,
      operation.OperationDescription,
      operation.Plant,
      operation.Equipment,
      cast ( operation.FunctionalLocation as char30 )       as FunctionalLocation,
      operation.FunctionalArea,
      operation.OperationWorkCenterInternalID,
      operation.OperationWorkCenterTypeCode,
      @ObjectModel.text.element: ['WorkCenterText']
      WC.WorkCenter                                         as WorkCenter,      
      WC.Description                                        as WorkCenterText,
      operation._MaintenanceOrder,
      operation._Plant,
      // Associations
      _Order
} where _StatusObjectActiveStatus.StatusObject is null
