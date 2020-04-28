package org.jesperancinha.logistics.jpa.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.ManyToOne;
import javax.persistence.Table;

@Entity
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "merchandise_log")
public class MerchandiseLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;
    private Long timestamp;
    /**
     * Status can be LOADED, INTRANSIT, DELIVERED
     */
    private String status;

    @ManyToOne
    private Company supplier;

    @ManyToOne
    private Company vendor;

    @ManyToOne
    private TransportPackage transportPackage;

    @ManyToOne
    private ProductCargo productCargo;
}
