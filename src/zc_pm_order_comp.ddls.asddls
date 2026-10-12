@EndUserText.label: 'PM Order Component - Projection'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define view entity ZC_PM_ORDER_COMP
  as projection on ZR_PM_ORDER_COMP
{
      @UI.hidden: true
  key MaintenanceOrder,
  key MaintOrderComponentInternalID,
  key ReservationItem,
      MaintenanceOrderOperation,
      MaintenanceOrderSubOperation,      
      Material,
      MaterialName,
      MaintenanceOrderComponentBatch,
      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      RequirementQuantityInBaseUnit,
      BaseUnit,
      Plant,
      StorageLocation,
      RequirementDate,
      _MaintenanceOrder,
      _Material,
      _Plant,

      _Order : redirected to parent ZC_PM_ORDER
}