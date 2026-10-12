@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PM Order Status'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZV_PM_ORDER_STATUS 
  as select from I_MaintenanceOrder as _order
  left outer join jest as j 
    on  j.objnr = _order.MaintenanceOrderInternalID
    and j.stat like 'E%'
    and j.inact = ''
{
    key _order.MaintenanceOrder,
        j.stat,

    max(
        case 
            when j.stat = 'E0001' then 1 
            else 0 
        end
    ) as BStatus1,

    max(
        case 
            when j.stat = 'E0002' then 2 
            else 0 
        end
    ) as BStatus2,

    max(
        case 
            when j.stat = 'E0003' then 3 
            else 0 
        end
    ) as BStatus3,

    max(
        case 
            when j.stat = 'E0003' then 1 
            else 0 
        end
    ) as BStatus4

}
group by _order.MaintenanceOrder,j.stat;