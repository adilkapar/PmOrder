@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'BM - Notification Partner (Child Entity)'

define view entity ZR_PM_ORDER_PARTNER
  as select from ZV_PM_ORDER_PARTNER as partner
  association to parent ZR_PM_ORDER as _Order on $projection.MaintenanceOrder = _Order.MaintenanceOrder
{
  key partner.MaintenanceOrder,
  key partner.PartnerFunction,
  key partner.PartnerCounter, 
      partner.Partner,

      _Order
}