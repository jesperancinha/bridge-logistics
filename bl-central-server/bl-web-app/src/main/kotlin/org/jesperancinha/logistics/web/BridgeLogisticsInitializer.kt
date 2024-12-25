package org.jesperancinha.logistics.web

import com.fasterxml.jackson.databind.ObjectMapper
import org.jesperancinha.logistics.jpa.dao.*
import org.jesperancinha.logistics.web.dto.CarriageFullDto
import org.jesperancinha.logistics.web.dto.ContainerFullDto
import org.jesperancinha.logistics.web.dto.FreightDto
import org.jesperancinha.logistics.web.dto.TrainDto
import org.springframework.boot.CommandLineRunner
import org.springframework.context.annotation.Profile
import org.springframework.data.repository.findByIdOrNull
import org.springframework.stereotype.Component
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.util.*
import java.util.function.Consumer
import java.util.stream.Collectors

@Component
@Profile("default","local", "demo")
class BridgeLogisticsInitializer(
    private val bridgeRepository: BridgeRepository,
    private val carriageRepository: CarriageRepository,
    private val containerRepository: ContainerRepository,
    private val freightRepository: FreightRepository,
    private val productRepository: ProductRepository,
    private val trainRepository: TrainRepository,
    private val openingTimeRepository: OpeningTimeRepository,
    private val companyRepository: CompanyRepository,
    private val passengerRepository: PassengerRepository
) : CommandLineRunner {
    private val objectMapper = ObjectMapper()

    @Throws(Exception::class)
    @Transactional
    override fun run(vararg args: String) {
        bridgeRepository.saveAll(
            listOf(
                *objectMapper.readValue(
                    javaClass.getResourceAsStream("/bridges.json"),
                    Array<Bridge>::class.java
                )
            )
        )
        companyRepository.saveAll(
            listOf(
                *objectMapper.readValue(
                    javaClass.getResourceAsStream("/companies.json"),
                    Array<Company>::class.java
                )
            )
        )
        carriageRepository.saveAll(
            listOf(
                *objectMapper.readValue(
                    javaClass.getResourceAsStream("/carriages.json"),
                    Array<Carriage>::class.java
                )
            )
        )
        containerRepository.saveAll(
            listOf(
                *objectMapper.readValue(
                    javaClass.getResourceAsStream("/containers.json"),
                    Array<Container>::class.java
                )
            )
        )
        productRepository.saveAll(
            listOf(
                *objectMapper.readValue(
                    javaClass.getResourceAsStream("/products.json"),
                    Array<Product>::class.java
                )
            )
        )
        passengerRepository.saveAll(
            listOf(
                *objectMapper.readValue(
                    javaClass.getResourceAsStream("/passengers/passengers.json"),
                    Array<Passenger>::class.java
                )
            )
        )
        objectMapper.readValue(
            javaClass.getResourceAsStream("/freight.json"),
            Array<FreightDto>::class.java
        ).map { freightDto: FreightDto ->
            Freight(
                id = freightDto.id,
                name = freightDto.name,
                type = freightDto.type,
                containers = freightDto.composition.mapNotNull { containerFullDto: ContainerFullDto ->
                    containerRepository.findById(containerFullDto.containerId)
                        .orElse(null)
                },
                supplier = companyRepository.findByIdOrNull(freightDto.supplierId),
                vendor =
                companyRepository.findByIdOrNull(freightDto.vendorId)
            )
        }.forEach(freightRepository::save)

        objectMapper.readValue(javaClass.getResourceAsStream("/train.json"), Array<TrainDto>::class.java)
            .map { trainDto ->
                Train(
                    id = trainDto.id,
                    name = trainDto.name,
                    type = trainDto.type,
                    carriages = trainDto.composition
                        .stream()
                        .map { carriageFullDto: CarriageFullDto ->
                            carriageRepository.findById(carriageFullDto.carriageId)
                                .orElse(null)
                        }
                        .filter { obj: Carriage? -> Objects.nonNull(obj) }
                        .collect(Collectors.toList()),
                    supplier =
                    companyRepository.findByIdOrNull(trainDto.supplierId),
                    vendor =
                    companyRepository.findByIdOrNull(trainDto.vendorId),
                )
            }
            .forEach(trainRepository::save)

        bridgeRepository.findAll()
            .forEach(Consumer { bridge ->
                val now = Instant.now()
                val millisToAdd: Long = 10000
                (0..200)
                    .map { integer: Int ->
                        BridgeOpeningTime(
                            id = integer.toLong(),
                            bridge = bridge,
                            openingTime =
                            now.plusMillis(millisToAdd * integer * 2)
                                .toEpochMilli(),
                            closingTime =
                            now.plusMillis(millisToAdd * (integer * 2 + 1))
                                .toEpochMilli()
                        )
                    }
                    .forEach(openingTimeRepository::save)
            })
    }
}