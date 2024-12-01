package org.jesperancinha.logistics.mcs.dto

import com.fasterxml.jackson.annotation.JsonProperty
import org.jesperancinha.logistics.jpa.dao.Status
import org.jesperancinha.logistics.jpa.dao.TrainType
import java.math.BigDecimal
import java.util.UUID

data class CarrierDto(
    @JsonProperty("carriageId")
    val carriageId: UUID,
    @JsonProperty("containerId")
    val containerId: UUID,
    @JsonProperty("packageId")
    val packageId: UUID,
    @JsonProperty("weight")
    val weight: Long,
    @JsonProperty("products")
    val products: List<ProductInTransitDto>
)

data class ContainerDto(
    @JsonProperty("containerId")
    val containerId: UUID,
    val packageId: UUID,
    val products: List<ProductInTransitDto>
)

class ProductInTransitDto(
    @JsonProperty("productId")
    val productId: UUID,
    @JsonProperty("quantity")
    val quantity: Long
)

data class TrainMerchandiseDto(
    @JsonProperty("id")
    val id: UUID?,
    @JsonProperty("name")
    val name: String?,
    @JsonProperty("supplierId")
    val supplierId: UUID?,
    @JsonProperty("vendorId")
    val vendorId: UUID?,
    @JsonProperty("type")
    val type: TrainType?,
    @JsonProperty("status")
    val status: Status?,
    @JsonProperty("composition")
    val composition: List<CarrierDto>?,
    @JsonProperty("lat")
    val lat: BigDecimal?,
    @JsonProperty("lon")
    val lon: BigDecimal?
)