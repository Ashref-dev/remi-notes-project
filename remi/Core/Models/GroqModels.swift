import Foundation

// MARK: - Groq Model Configuration
struct GroqModel: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let contextLength: Int
    let inputPricing: Double  // per 1M tokens
    let outputPricing: Double // per 1M tokens
    let category: ModelCategory
    let capabilities: [ModelCapability]
    let recommendedUseCase: String
    
    enum ModelCategory: String, CaseIterable, Codable {
        case general = "General Purpose"
        case coding = "Code Generation"
        case reasoning = "Reasoning & Analysis"
        case creative = "Creative Writing"
        case fast = "Fast Response"
        
        var icon: String {
            switch self {
            case .general: return "brain.head.profile"
            case .coding: return "curlybraces"
            case .reasoning: return "lightbulb"
            case .creative: return "paintbrush"
            case .fast: return "bolt"
            }
        }
        
        var color: String {
            switch self {
            case .general: return "blue"
            case .coding: return "green"
            case .reasoning: return "purple"
            case .creative: return "orange"
            case .fast: return "yellow"
            }
        }
    }
    
    enum ModelCapability: String, CaseIterable, Codable {
        case multimodal = "Multimodal"
        case functionCalling = "Function Calling"
        case jsonMode = "JSON Mode"
        case highSpeed = "High Speed"
        case highQuality = "High Quality"
        case longContext = "Long Context"
        
        var icon: String {
            switch self {
            case .multimodal: return "photo.on.rectangle"
            case .functionCalling: return "function"
            case .jsonMode: return "doc.text"
            case .highSpeed: return "speedometer"
            case .highQuality: return "star"
            case .longContext: return "doc.on.doc"
            }
        }
    }
}

// MARK: - Model Registry
struct GroqModelRegistry {
    static let availableModels: [GroqModel] = [
        // Qwen Models
        GroqModel(
            id: "qwen/qwen3-32b",
            name: "Qwen 3 32B",
            description: "Alibaba's powerful multilingual model with excellent reasoning",
            contextLength: 131072,
            inputPricing: 0.0,
            outputPricing: 0.0,
            category: .reasoning,
            capabilities: [.highQuality, .longContext],
            recommendedUseCase: "Complex reasoning, multilingual tasks, detailed analysis"
        ),
        
        // OpenAI GPT-OSS Models
        GroqModel(
            id: "openai/gpt-oss-20b",
            name: "GPT-OSS 20B",
            description: "OpenAI's compact open-weight model with reasoning capabilities",
            contextLength: 131072,
            inputPricing: 0.0,
            outputPricing: 0.0,
            category: .reasoning,
            capabilities: [.highQuality, .longContext, .functionCalling],
            recommendedUseCase: "Reasoning tasks, code analysis, general problem solving"
        ),
        
        GroqModel(
            id: "openai/gpt-oss-120b",
            name: "GPT-OSS 120B",
            description: "OpenAI's flagship open-weight model with advanced reasoning",
            contextLength: 131072,
            inputPricing: 0.0,
            outputPricing: 0.0,
            category: .reasoning,
            capabilities: [.highQuality, .longContext, .functionCalling],
            recommendedUseCase: "Advanced reasoning, complex analysis, research tasks"
        ),
        
        // Moonshot AI
        GroqModel(
            id: "moonshotai/kimi-k2-instruct",
            name: "Kimi K2 Instruct",
            description: "Moonshot AI's instruction-tuned model with long context",
            contextLength: 131072,
            inputPricing: 0.0,
            outputPricing: 0.0,
            category: .general,
            capabilities: [.longContext, .highQuality],
            recommendedUseCase: "Long document processing, instruction following"
        ),
        
        // Meta Llama 4 Models
        GroqModel(
            id: "meta-llama/llama-4-scout-17b-16e-instruct",
            name: "Llama 4 Scout 17B",
            description: "Meta's efficient Llama 4 model with strong reasoning",
            contextLength: 131072,
            inputPricing: 0.0,
            outputPricing: 0.0,
            category: .reasoning,
            capabilities: [.highQuality, .longContext],
            recommendedUseCase: "Balanced reasoning and efficiency, general tasks"
        ),
        
        GroqModel(
            id: "meta-llama/llama-4-maverick-17b-128e-instruct",
            name: "Llama 4 Maverick 17B",
            description: "Meta's advanced Llama 4 variant with enhanced capabilities",
            contextLength: 131072,
            inputPricing: 0.0,
            outputPricing: 0.0,
            category: .reasoning,
            capabilities: [.highQuality, .longContext],
            recommendedUseCase: "Advanced reasoning, complex problem solving"
        ),
        
        // Meta Llama 3.3 & 3.1
        GroqModel(
            id: "llama-3.3-70b-versatile",
            name: "Llama 3.3 70B Versatile",
            description: "Meta's versatile large model for complex tasks",
            contextLength: 131072,
            inputPricing: 0.0,
            outputPricing: 0.0,
            category: .general,
            capabilities: [.highQuality, .longContext, .functionCalling],
            recommendedUseCase: "Versatile tasks, content creation, analysis"
        ),
        
        GroqModel(
            id: "llama-3.1-8b-instant",
            name: "Llama 3.1 8B Instant",
            description: "Fast and efficient model for quick responses",
            contextLength: 131072,
            inputPricing: 0.0,
            outputPricing: 0.0,
            category: .fast,
            capabilities: [.highSpeed, .longContext],
            recommendedUseCase: "Quick responses, fast processing, instant tasks"
        ),
        
        // DeepSeek R1
        GroqModel(
            id: "deepseek-r1-distill-llama-70b",
            name: "DeepSeek R1 Distill 70B",
            description: "DeepSeek's reasoning-focused model based on Llama",
            contextLength: 131072,
            inputPricing: 0.0,
            outputPricing: 0.0,
            category: .reasoning,
            capabilities: [.highQuality, .longContext],
            recommendedUseCase: "Advanced reasoning, mathematical problems, logic tasks"
        ),
        
        // Allam Model
        GroqModel(
            id: "allam-2-7b",
            name: "Allam 2 7B",
            description: "IBM's efficient multilingual model",
            contextLength: 8192,
            inputPricing: 0.0,
            outputPricing: 0.0,
            category: .general,
            capabilities: [.highSpeed],
            recommendedUseCase: "Multilingual tasks, efficient processing, general use"
        )
    ]
    
    static let defaultModelId = "llama-3.1-8b-instant"
    
    static func model(withId id: String) -> GroqModel? {
        return availableModels.first { $0.id == id }
    }
    
    static func modelsByCategory() -> [GroqModel.ModelCategory: [GroqModel]] {
        return Dictionary(grouping: availableModels, by: { $0.category })
    }
}

// MARK: - Model Parameters
struct ModelParameters: Codable {
    var temperature: Double
    var maxTokens: Int
    var topP: Double
    var frequencyPenalty: Double
    var presencePenalty: Double
    
    static let `default` = ModelParameters(
        temperature: 0.3,
        maxTokens: 4000,
        topP: 0.9,
        frequencyPenalty: 0.0,
        presencePenalty: 0.0
    )
    
    static let creative = ModelParameters(
        temperature: 0.8,
        maxTokens: 4000,
        topP: 0.9,
        frequencyPenalty: 0.3,
        presencePenalty: 0.3
    )
    
    static let precise = ModelParameters(
        temperature: 0.1,
        maxTokens: 4000,
        topP: 0.8,
        frequencyPenalty: 0.0,
        presencePenalty: 0.0
    )
    
    static let balanced = ModelParameters(
        temperature: 0.5,
        maxTokens: 4000,
        topP: 0.9,
        frequencyPenalty: 0.1,
        presencePenalty: 0.1
    )
}
