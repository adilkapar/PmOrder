@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PM order Componets view'
define view entity ZR_PM_ORDER_COMP
  as select from I_MaintenanceOrderComponent_2
  association        to parent ZR_PM_ORDER as _Order        on  $projection.MaintenanceOrder = _Order.MaintenanceOrder
  association [0..1] to I_MaterialText     as _MaterialText on  _MaterialText.Material = $projection.Material
                                                            and _MaterialText.Language = $session.system_language
{
  key  MaintenanceOrder,
  key  MaintOrderComponentInternalID,
  key  ReservationItem,
       MaintenanceOrderOperation,
       MaintenanceOrderSubOperation,
       @ObjectModel.text.element: ['MaterialName']
       Material,
       _MaterialText.MaterialName as MaterialName,
       MaintenanceOrderComponentBatch,
       @Semantics.quantity.unitOfMeasure: 'BaseUnit'
       RequirementQuantityInBaseUnit,
       BaseUnit,
       Plant,
       StorageLocation,
       RequirementDate,
       _MaintenanceOrder,
       _Material,
       _MaterialText,
       _Plant,

       _Order
} where IsDeleted = ''
