//
//  ScannerView.swift
//  El goman
//
//  Created by Roberto Fiori.
//

import SwiftUI
import AVFoundation

public struct ScannerView: View {
    @Environment(AppState.self) private var appState

    @State private var manualBarcode = ""
    @State private var isScanning = true
    @State private var isProcessing = false
    @State private var scannedProduct: ProductData?
    @State private var scannedPrices: [SupermarketPrice] = []
    @State private var showResultSheet = false
    @State private var statusMessage = "Apunta la cámara al código de barras del producto"

    private let sampleBarcodes = [
        ("7790070507204", "Aceite Natura 1.5L"),
        ("7790742330602", "Leche La Serenísima 1L"),
        ("7790580982704", "Arroz Lucchetti 1kg")
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Visor de Cámara / Escáner
                ZStack {
                    #if targetEnvironment(simulator)
                    simulatorCameraMock
                    #else
                    CameraScannerRepresentable { code in
                        handleScannedBarcode(code)
                    }
                    .ignoresSafeArea(edges: .top)
                    #endif

                    // Retícula de escaneo
                    scannerOverlay
                }
                .frame(maxHeight: .infinity)

                // Panel inferior: Entrada manual & Ejemplos rápidos
                bottomControlPanel
            }
            .navigationTitle("Escanear")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showResultSheet) {
                scannedResultSheet
            }
        }
    }

    // MARK: - Scanner Overlay
    private var scannerOverlay: some View {
        VStack {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.green, lineWidth: 3)
                    .frame(width: 260, height: 160)
                    .background(Color.black.opacity(0.1))

                if isProcessing {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.green)
                }
            }

            Text(statusMessage)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.65))
                .clipShape(Capsule())
                .padding(.top, 16)

            Spacer()
        }
    }

    // MARK: - Simulator Mock
    private var simulatorCameraMock: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 60))
                    .foregroundColor(.green.opacity(0.8))
                Text("Simulador de Cámara")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Usa los botones rápidos o escribe un código manual para probar.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - Bottom Control Panel
    private var bottomControlPanel: some View {
        VStack(spacing: 14) {
            // Códigos de ejemplo rápido
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sampleBarcodes, id: \.0) { sample in
                        Button(action: {
                            handleScannedBarcode(sample.0)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "barcode")
                                    .font(.caption2)
                                Text(sample.1)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Entrada manual
            HStack(spacing: 10) {
                TextField("Escribir código de barras (EAN)...", text: $manualBarcode)
                    .keyboardType(.numberPad)
                    .font(.subheadline)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                Button("Consultar") {
                    if !manualBarcode.isEmpty {
                        handleScannedBarcode(manualBarcode)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(manualBarcode.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .padding(.top, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - Handle Scanned Code
    private func handleScannedBarcode(_ barcode: String) {
        guard !isProcessing else { return }
        isProcessing = true
        statusMessage = "Buscando código \(barcode)..."
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        Task {
            // 1. Consultar Open Food Facts
            let productData = await BarcodeService.shared.fetchProductInfo(barcode: barcode)

            // 2. Consultar Precios en supermercados
            let query = productData?.productName ?? barcode
            let prices = (try? await PriceService.shared.searchPrices(
                query: query,
                location: appState.selectedLocation
            )) ?? []

            await MainActor.run {
                self.scannedProduct = productData
                self.scannedPrices = prices
                self.isProcessing = false
                self.statusMessage = "Producto encontrado"
                self.showResultSheet = true
            }
        }
    }

    // MARK: - Scanned Result Sheet
    private var scannedResultSheet: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        if let img = scannedProduct?.imageUrl, let url = URL(string: img) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 70, height: 70)
                                } else {
                                    Image(systemName: "barcode")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(width: 70, height: 70)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(scannedProduct?.productName ?? "Producto escaneado")
                                .font(.headline)
                                .foregroundColor(.primary)

                            if let brand = scannedProduct?.brands {
                                Text(brand)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if let qty = scannedProduct?.quantity {
                                Text(qty)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Precios en Supermercados") {
                    if scannedPrices.isEmpty {
                        Text("No encontramos precios activos para este producto en \(appState.selectedLocation.city).")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(scannedPrices) { price in
                            ProductSearchResultRow(price: price) {
                                appState.addToCart(
                                    productName: price.productName ?? scannedProduct?.productName ?? "Producto",
                                    brand: price.brand ?? scannedProduct?.brands,
                                    imageUrl: price.imageUrl ?? scannedProduct?.imageUrl,
                                    selectedPrice: price,
                                    allPrices: scannedPrices,
                                    quantity: 1,
                                    ean: scannedProduct?.code
                                )
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Detalle de Escaneo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        showResultSheet = false
                        statusMessage = "Apunta la cámara al código de barras del producto"
                    }
                }
            }
        }
    }
}

// MARK: - Native AVCapture Barcode Scanner Representable
#if !targetEnvironment(simulator)
struct CameraScannerRepresentable: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let vc = BarcodeScannerViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onCodeScanned: (String) -> Void
        private var lastCode = ""
        private var lastScanTime = Date.distantPast

        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let stringValue = metadataObject.stringValue else { return }

            if stringValue != lastCode || Date().timeIntervalSince(lastScanTime) > 3.0 {
                lastCode = stringValue
                lastScanTime = Date()
                DispatchQueue.main.async {
                    self.onCodeScanned(stringValue)
                }
            }
        }
    }
}

final class BarcodeScannerViewController: UIViewController {
    var delegate: AVCaptureMetadataOutputObjectsDelegate?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13, .ean8, .qr, .upce, .code128]
        }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        self.previewLayer = preview
        self.captureSession = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
}
#endif
