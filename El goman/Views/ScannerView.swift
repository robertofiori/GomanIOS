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

    @State private var scannedCode: String?
    @State private var scannedProduct: ProductData?
    @State private var scannedPrices: [SupermarketPrice] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var showProductDetail = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                // Vista de cámara simulada / real
                CameraPreviewView { barcode in
                    handleBarcodeScanned(barcode)
                }
                .ignoresSafeArea()

                // Overlay con mira de escaneo
                VStack {
                    Spacer()

                    // Recuadro visor de escaneo
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.8), lineWidth: 2)
                            .frame(width: 260, height: 160)

                        // Animación de línea láser
                        LaserLineView()
                            .frame(width: 240, height: 140)
                    }

                    Text("Alineá el código de barras dentro del marco")
                        .font(.footnote)
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                        .padding(.top, 16)

                    Spacer()

                    // Indicador de carga al detectar
                    if isSearching {
                        VStack(spacing: 8) {
                            ProgressView()
                                .tint(.white)
                            Text("Buscando en supermercados...")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.bottom, 24)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.white)
                            .clipShape(Capsule())
                            .padding(.bottom, 24)
                    }
                }
                .padding()
            }
            .navigationTitle("Escanear Producto")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showProductDetail) {
                productDetailSheet
            }
        }
    }

    private func handleBarcodeScanned(_ code: String) {
        guard scannedCode != code && !isSearching else { return }
        scannedCode = code
        isSearching = true
        errorMessage = nil

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        Task {
            // 1. Obtener datos del producto vía Open Food Facts
            let product = await BarcodeService.shared.fetchProductInfo(barcode: code)

            // 2. Buscar precios en los supermercados de Bahía Blanca
            let searchTerm = product?.productName ?? code
            var prices: [SupermarketPrice] = []
            do {
                prices = try await PriceService.shared.searchPrices(
                    query: searchTerm,
                    location: appState.selectedLocation
                )
            } catch {
                // Si falla por término, reintentamos con el barcode directo
                if let fallback = try? await PriceService.shared.searchPrices(query: code, location: appState.selectedLocation) {
                    prices = fallback
                }
            }

            await MainActor.run {
                self.scannedProduct = product
                self.scannedPrices = prices
                self.isSearching = false
                self.showProductDetail = true
            }
        }
    }

    // MARK: - Detalle del producto escaneado
    private var productDetailSheet: some View {
        NavigationStack {
            List {
                Section("Producto Identificado") {
                    HStack(spacing: 12) {
                        if let img = scannedProduct?.imageUrl, let url = URL(string: img) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    Image(systemName: "barcode.viewfinder")
                                        .font(.title)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Image(systemName: "barcode.viewfinder")
                                .font(.title)
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(scannedProduct?.productName ?? "Código: \(scannedCode ?? "")")
                                .font(.headline)

                            if let brand = scannedProduct?.brands {
                                Text(brand)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            if let qty = scannedProduct?.quantity {
                                Text(qty)
                                    .font(.caption)
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
                            ProductSearchResultRow(
                                price: price,
                                isBestPrice: price.id == scannedPrices.first?.id,
                                bestSavingsVsHighest: nil
                            ) { qty, isOptional in
                                appState.addToCart(
                                    productName: price.productName ?? scannedProduct?.productName ?? "Producto",
                                    brand: price.brand ?? scannedProduct?.brands,
                                    imageUrl: price.imageUrl ?? scannedProduct?.imageUrl,
                                    selectedPrice: price,
                                    allPrices: scannedPrices,
                                    quantity: qty,
                                    isOptional: isOptional,
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        showProductDetail = false
                        scannedCode = nil
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Visor Láser Animado
private struct LaserLineView: View {
    @State private var offset: CGFloat = -60

    var body: some View {
        Rectangle()
            .fill(Color.red.opacity(0.8))
            .frame(height: 2)
            .shadow(color: .red, radius: 4, x: 0, y: 0)
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = 60
                }
            }
    }
}

// MARK: - Camera Preview Wrapper
private struct CameraPreviewView: UIViewControllerRepresentable {
    let onBarcodeFound: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let vc = BarcodeScannerViewController()
        vc.onBarcodeScanned = onBarcodeFound
        return vc
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}
}

private class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onBarcodeScanned: ((String) -> Void)?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupCamera() {
        let session = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .qr, .upce, .code128]
        } else {
            return
        }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.layer.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)

        self.previewLayer = preview
        self.captureSession = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            onBarcodeScanned?(stringValue)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
}
